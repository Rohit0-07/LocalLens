from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import AppError
from app.core.logging import get_logger
from app.features.geo.schemas import MapPinOut, ReverseGeocodeOut, ReverseGeocodeWardOut
from app.features.issues.geo import haversine_km
from app.features.issues.models import Issue
from app.features.wards.models import Ward

logger = get_logger(__name__)


async def get_map_pins(
    session: AsyncSession,
    min_lat: float | None = None,
    max_lat: float | None = None,
    min_lng: float | None = None,
    max_lng: float | None = None,
    category: str | None = None,
    status: str | None = None,
) -> list[MapPinOut]:
    """Retrieve map pins for issues within the specified bounding box.

    Applies privacy filtering:
    - Excludes hidden issues (is_hidden == True).
    - Excludes shielded non-resolved issues (is_shielded == True and status != 'resolved').
    """
    if min_lat is None or not (-90.0 <= min_lat <= 90.0):
        min_lat = 8.0
    if max_lat is None or not (-90.0 <= max_lat <= 90.0):
        max_lat = 37.0
    if min_lng is None or not (-180.0 <= min_lng <= 180.0):
        min_lng = 68.0
    if max_lng is None or not (-180.0 <= max_lng <= 180.0):
        max_lng = 97.0

    if min_lat > max_lat:
        min_lat, max_lat = 8.0, 37.0
    if min_lng > max_lng:
        min_lng, max_lng = 68.0, 97.0

    stmt = select(Issue).where(
        Issue.latitude >= min_lat,
        Issue.latitude <= max_lat,
        Issue.longitude >= min_lng,
        Issue.longitude <= max_lng,
        Issue.is_hidden.is_(False),
        ~((Issue.is_shielded.is_(True)) & (Issue.status != "resolved")),
    )

    if category and category.strip() and category.lower() != "all":
        stmt = stmt.where(Issue.category == category)

    if status and status.strip() and status.lower() != "all":
        stmt = stmt.where(Issue.status == status)

    stmt = stmt.order_by(Issue.created_at.desc())
    result = await session.execute(stmt)
    issues = result.scalars().all()

    return [
        MapPinOut(
            id=issue.id,
            title=issue.title,
            category=issue.category,
            status=issue.status,
            latitude=issue.latitude,
            longitude=issue.longitude,
            ward_name=issue.ward,
            is_shielded=issue.is_shielded,
            upvotes_count=issue.upvotes_count,
            created_at=issue.created_at,
        )
        for issue in issues
    ]


async def reverse_geocode(
    session: AsyncSession,
    latitude: float,
    longitude: float,
    radius_km: float,
) -> ReverseGeocodeOut:
    """Resolve the nearest ward center to the given coordinates.

    Reads the full ward registry (one SELECT, no writes) and computes the
    great-circle distance from ``(latitude, longitude)`` to every ward center
    with ``haversine_km``.

    Semantics:

    - Rounding: Python ``round(x, 1)`` (banker's rounding); the returned
      ``distance_km`` is accurate to one decimal place.
    - Radius is inclusive: a location exactly ``radius_km`` from a ward
      center IS found.
    - Tie-break: when two wards are equidistant, the first ward in table
      order wins (stable, deterministic).
    - When no ward is within ``radius_km``, the response has ``found=False``,
      ``ward=None``, ``place="Outside coverage"`` and ``distance_km=0.0``.

    Read-only: this function never writes to the database.
    """
    stmt = select(
        Ward.id,
        Ward.slug,
        Ward.name,
        Ward.code,
        Ward.center_latitude,
        Ward.center_longitude,
    )
    rows = (await session.execute(stmt)).all()

    min_distance = float("inf")
    nearest: ReverseGeocodeWardOut | None = None

    for row in rows:
        distance = haversine_km(latitude, longitude, row.center_latitude, row.center_longitude)
        if distance < min_distance:
            min_distance = distance
            nearest = ReverseGeocodeWardOut(
                slug=row.slug,
                name=row.name,
                code=row.code,
                center_latitude=row.center_latitude,
                center_longitude=row.center_longitude,
            )

    if nearest is not None and min_distance <= radius_km:
        logger.info("reverse_geocode outcome: ward=%s found=True", nearest.slug)
        return ReverseGeocodeOut(
            latitude=latitude,
            longitude=longitude,
            place=nearest.name,
            ward=nearest,
            distance_km=round(min_distance, 1),
            found=True,
        )

    logger.info("reverse_geocode outcome: ward=None found=False")
    return ReverseGeocodeOut(
        latitude=latitude,
        longitude=longitude,
        place="Outside coverage",
        ward=None,
        distance_km=0.0,
        found=False,
    )
