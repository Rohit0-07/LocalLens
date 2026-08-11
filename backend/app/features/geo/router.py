from fastapi import APIRouter, Query, Request

from app.api.deps import SessionDep
from app.core.exceptions import AppError
from app.core.ratelimit import SlidingWindowRateLimiter
from app.features.geo import service
from app.features.geo.schemas import MapPinOut, ReverseGeocodeOut

router = APIRouter(prefix="/geo", tags=["geo"])


def _check_rate_limit(request: Request) -> None:
    if not hasattr(request.app.state, "geo_rate_limiter"):
        request.app.state.geo_rate_limiter = SlidingWindowRateLimiter(
            max_requests=60, window_seconds=60
        )
    limiter: SlidingWindowRateLimiter = request.app.state.geo_rate_limiter
    client_ip = request.client.host if request.client else "unknown"
    if not limiter.allow(client_ip):
        raise AppError(status_code=429, detail="Rate limit exceeded", code="rate_limit_exceeded")


@router.get("/reverse-geocode", response_model=ReverseGeocodeOut)
async def reverse_geocode_endpoint(
    request: Request,
    session: SessionDep,
    latitude: float = Query(..., ge=-90.0, le=90.0),
    longitude: float = Query(..., ge=-180.0, le=180.0),
    radius_km: float = Query(50.0, ge=0.1, le=50.0),
) -> ReverseGeocodeOut:
    _check_rate_limit(request)
    return await service.reverse_geocode(
        session, latitude=latitude, longitude=longitude, radius_km=radius_km
    )


@router.get("/map-pins", response_model=list[MapPinOut])
async def get_map_pins_endpoint(
    request: Request,
    session: SessionDep,
    min_lat: float | None = Query(None),
    max_lat: float | None = Query(None),
    min_lng: float | None = Query(None),
    max_lng: float | None = Query(None),
    category: str | None = Query(None),
    status: str | None = Query(None),
) -> list[MapPinOut]:
    _check_rate_limit(request)
    return await service.get_map_pins(
        session,
        min_lat=min_lat,
        max_lat=max_lat,
        min_lng=min_lng,
        max_lng=max_lng,
        category=category,
        status=status,
    )
