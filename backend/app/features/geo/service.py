import json
import math

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.logging import get_logger
from app.features.geo.schemas import (
    MapPinOut,
    ReverseGeocodeOut,
    ReverseGeocodeWardOut,
    WardBoundaryOut,
)
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
        stmt = stmt.where(func.lower(func.trim(Issue.category)) == category.strip().lower())

    if status and status.strip() and status.lower() != "all":
        stmt = stmt.where(func.lower(func.trim(Issue.status)) == status.strip().lower())

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


def derived_boundary_ring(lat: float, lng: float) -> list[list[float]]:
    """Deterministic 8-point octagon ring around ``(lat, lng)``.

    Radius is 0.02° in latitude and ``0.02 / cos(lat)`` in longitude so the
    ring stays ~2.2 km wide regardless of latitude — the same algorithm as the
    frontend ``derivedWardRing`` helper. Points are ordered clockwise starting
    at due north.
    """
    radius_lat = 0.02
    radius_lng = 0.02 / math.cos(math.radians(lat))
    return [
        [
            round(lat + radius_lat * math.cos(math.radians(angle)), 6),
            round(lng + radius_lng * math.sin(math.radians(angle)), 6),
        ]
        for angle in (0, 45, 90, 135, 180, 225, 270, 315)
    ]


def parse_ward_boundary(raw: str | None) -> list[list[float]] | None:
    """Parse a ward boundary ring from its JSON-encoded text column.

    Returns ``None`` when the value is missing, empty, not JSON, not a list,
    has fewer than 3 points, or contains any point that is not a ``[lat, lng]``
    pair within valid coordinate ranges. Callers fall back to
    :func:`derived_boundary_ring` in that case so the map always shows a
    meaningful polygon.
    """
    if not raw:
        return None
    try:
        data = json.loads(raw)
    except (TypeError, ValueError):
        return None
    if not isinstance(data, list) or len(data) < 3:
        return None

    ring: list[list[float]] = []
    for point in data:
        if not isinstance(point, (list, tuple)) or len(point) != 2:
            return None
        lat, lng = point
        if isinstance(lat, bool) or isinstance(lng, bool):
            return None
        if not isinstance(lat, (int, float)) or not isinstance(lng, (int, float)):
            return None
        if not (-90.0 <= lat <= 90.0) or not (-180.0 <= lng <= 180.0):
            return None
        ring.append([float(lat), float(lng)])
    return ring


async def list_ward_boundaries(session: AsyncSession) -> list[WardBoundaryOut]:
    """Return every ward with its boundary ring (derived fallback when malformed).

    Read-only: one SELECT, no writes. Always returns 200 with an empty list
    when the ``wards`` table is empty. A malformed/``NULL`` boundary degrades
    to the deterministic derived octagon so the map never 5xxes and always
    draws a meaningful polygon.
    """
    stmt = select(Ward).order_by(Ward.id)
    rows = (await session.execute(stmt)).scalars().all()

    result: list[WardBoundaryOut] = []
    for ward in rows:
        ring = parse_ward_boundary(ward.boundary)
        if ring is None:
            ring = derived_boundary_ring(ward.center_latitude, ward.center_longitude)
        result.append(
            WardBoundaryOut(
                ward_slug=ward.slug,
                name=ward.name,
                code=ward.code,
                boundary=ring,
            )
        )
    return result
