"""Feature F-A (backend): EXIF GPS embedding + captured_at echo.

Covers:
  - unit round-trip: the embedder writes GPSInfo (tag 34853) with coordinates
    within 1e-6 of the input,
  - ``POST /api/v1/media/upload`` with ``captured_lat``/``captured_lng`` stores
    a file whose served bytes contain GPSInfo,
  - uploads without coordinates carry no GPSInfo,
  - ``captured_at`` is echoed back in the upload response.
"""

import base64
from datetime import datetime
from io import BytesIO

import httpx
import pytest
from PIL import Image
from PIL.ExifTags import IFD

pytestmark = pytest.mark.asyncio


def _make_jpeg_bytes() -> bytes:
    """Return a tiny, valid JPEG so PIL can round-trip EXIF data."""
    buffer = BytesIO()
    Image.new("RGB", (64, 64), color=(120, 80, 40)).save(buffer, format="JPEG")
    return buffer.getvalue()


def _as_float(value):
    """Normalize a PIL rational / IFDRational / DMS tuple to a float."""
    if isinstance(value, tuple):
        if len(value) == 3:  # DMS: (deg, minutes, seconds)
            deg, minutes, seconds = value
            return (
                _as_float(deg)
                + _as_float(minutes) / 60.0
                + _as_float(seconds) / 3600.0
            )
        if len(value) == 2:  # single rational (numerator, denominator)
            return _as_float(value[0]) / _as_float(value[1])
    return float(value)


def _gps_to_decimal(gps_ifd):
    """Extract (lat, lng) decimal degrees from a PIL GPSInfo IFD dict."""
    lat = _as_float(gps_ifd[2])
    lng = _as_float(gps_ifd[4])
    if str(gps_ifd.get(1, "")).upper() == "S":
        lat = -lat
    if str(gps_ifd.get(3, "")).upper() == "W":
        lng = -lng
    return lat, lng


async def test_embed_exif_gps_writes_gpsinfo():
    """Unit: EXIF GPS embedding writes GPSInfo (tag 34853) with input coords.

    Function name/signature follow the F-A plan §4 EXIF GPS embedding contract:
    ``embed_exif_gps(image_bytes, lat, lng) -> image_bytes``. If the interface
    contract names this function differently, only the import below changes.
    """
    from app.features.media.service import embed_exif_gps

    jpeg_bytes = _make_jpeg_bytes()
    embedded = embed_exif_gps(jpeg_bytes, lat=19.11, lng=72.87)

    exif = Image.open(BytesIO(embedded)).getexif()
    assert 34853 in exif  # GPSInfo IFD present

    gps = exif.get_ifd(IFD.GPSInfo)
    lat, lng = _gps_to_decimal(gps)
    assert abs(lat - 19.11) < 1e-6
    assert abs(lng - 72.87) < 1e-6


async def test_upload_with_coords_embeds_gps_exif(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    """Uploading with captured_lat/captured_lng stores a file with GPSInfo."""
    b64 = base64.b64encode(_make_jpeg_bytes()).decode("utf-8")
    res = await client.post(
        "/api/v1/media/upload",
        json={
            "base64_payload": b64,
            "is_in_app_camera": True,
            "captured_lat": 19.11,
            "captured_lng": 72.87,
        },
        headers=auth_headers,
    )
    assert res.status_code == 201, res.text
    data = res.json()

    file_res = await client.get(data["url"])
    assert file_res.status_code == 200

    exif = Image.open(BytesIO(file_res.content)).getexif()
    assert 34853 in exif
    lat, lng = _gps_to_decimal(exif.get_ifd(IFD.GPSInfo))
    assert abs(lat - 19.11) < 1e-6
    assert abs(lng - 72.87) < 1e-6


async def test_upload_without_coords_has_no_gps_exif(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    """Uploading without coordinates produces a file with no GPSInfo."""
    b64 = base64.b64encode(_make_jpeg_bytes()).decode("utf-8")
    res = await client.post(
        "/api/v1/media/upload",
        json={"base64_payload": b64, "is_in_app_camera": True},
        headers=auth_headers,
    )
    assert res.status_code == 201, res.text

    file_res = await client.get(res.json()["url"])
    assert file_res.status_code == 200

    exif = Image.open(BytesIO(file_res.content)).getexif()
    assert 34853 not in exif


async def test_captured_at_echoed_in_response(
    client: httpx.AsyncClient, auth_headers: dict[str, str]
) -> None:
    """Uploading with captured_at echoes the ISO timestamp in the response."""
    b64 = base64.b64encode(_make_jpeg_bytes()).decode("utf-8")
    captured_at = "2026-08-19T10:30:00"
    res = await client.post(
        "/api/v1/media/upload",
        json={
            "base64_payload": b64,
            "is_in_app_camera": True,
            "captured_lat": 19.11,
            "captured_lng": 72.87,
            "captured_at": captured_at,
        },
        headers=auth_headers,
    )
    assert res.status_code == 201, res.text
    echoed = res.json().get("captured_at")
    assert echoed is not None
    assert datetime.fromisoformat(echoed.replace("Z", "+00:00")) == datetime.fromisoformat(
        captured_at
    )
