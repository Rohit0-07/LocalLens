from datetime import datetime

from pydantic import BaseModel, ConfigDict


class ReverseGeocodeWardOut(BaseModel):
    model_config = ConfigDict(from_attributes=False)

    slug: str
    name: str
    code: str
    center_latitude: float
    center_longitude: float


class ReverseGeocodeOut(BaseModel):
    model_config = ConfigDict(from_attributes=False)

    latitude: float
    longitude: float
    place: str
    ward: ReverseGeocodeWardOut | None
    distance_km: float
    found: bool


class MapPinOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    category: str
    status: str
    latitude: float
    longitude: float
    ward_name: str
    is_shielded: bool
    upvotes_count: int
    created_at: datetime


class WardBoundaryOut(BaseModel):
    model_config = ConfigDict(from_attributes=False)

    ward_slug: str
    name: str
    code: str
    #: Outer ring as ``[[lat, lng], ...]`` (≥3 points, open or closed).
    boundary: list[list[float]]
