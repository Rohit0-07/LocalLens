import math

from sqlalchemy import Select, select
from sqlalchemy.orm import selectinload

from app.features.issues.models import Issue


def haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    radius = 6371.0
    d_lat = math.radians(lat2 - lat1)
    d_lng = math.radians(lng2 - lng1)
    a = (
        math.sin(d_lat / 2) ** 2
        + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(d_lng / 2) ** 2
    )
    return radius * 2 * math.asin(math.sqrt(a))


async def bbox_statement(
    latitude: float, longitude: float, radius_km: float
) -> Select[tuple[Issue]]:
    delta_lat = radius_km / 111.0
    delta_lng = radius_km / (111.0 * math.cos(math.radians(latitude))) if latitude != 90 else 0.0
    return (
        select(Issue)
        .options(selectinload(Issue.reporter))
        .where(
            Issue.latitude.between(latitude - delta_lat, latitude + delta_lat),
            Issue.longitude.between(longitude - delta_lng, longitude + delta_lng),
        )
    )
