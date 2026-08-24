import base64
from io import BytesIO

import pytest
from app.features.media.service import derive_media_hash, process_location, validate_verification
from httpx import AsyncClient
from PIL import Image


def _make_jpeg_bytes(color: tuple[int, int, int] = (120, 80, 40)) -> bytes:
    buffer = BytesIO()
    Image.new("RGB", (64, 64), color=color).save(buffer, format="JPEG")
    return buffer.getvalue()


def test_derive_media_hash():
    dummy_bytes = b"fake_image_content_12345"
    hash1 = derive_media_hash(dummy_bytes, user_id="user_1")
    hash2 = derive_media_hash(dummy_bytes, user_id="user_1")
    hash3 = derive_media_hash(dummy_bytes, user_id="user_2")

    assert hash1 == hash2
    assert hash1 != hash3
    assert len(hash1) == 64


def test_location_fuzzing():
    lat, lng = process_location(12.9715987, 77.5945627, is_fuzzed=True)
    assert lat == 12.97
    assert lng == 77.59

    lat_exact, lng_exact = process_location(12.9715987, 77.5945627, is_fuzzed=False)
    assert lat_exact == 12.9715987
    assert lng_exact == 77.5945627


def test_verification():
    is_ver, label = validate_verification(is_in_app_camera=True, lat=12.97, lng=77.59)
    assert is_ver is True
    assert label == "LocalLens Verified"

    is_ver_no_gps, label_no_gps = validate_verification(is_in_app_camera=True, lat=None, lng=None)
    assert is_ver_no_gps is False
    assert label_no_gps == "User Uploaded - Unverified"

    is_ver_gallery, label_gallery = validate_verification(
        is_in_app_camera=False, lat=12.97, lng=77.59
    )
    assert is_ver_gallery is False
    assert label_gallery == "User Uploaded - Unverified"


@pytest.mark.asyncio
async def test_upload_media_endpoint_json(client: AsyncClient, auth_headers: dict[str, str]):
    sample_bytes = _make_jpeg_bytes()
    b64_str = base64.b64encode(sample_bytes).decode("utf-8")

    payload = {
        "base64_payload": b64_str,
        "is_in_app_camera": True,
        "captured_lat": 12.9715,
        "captured_lng": 77.5945,
        "is_fuzzed": True,
    }

    res = await client.post("/api/v1/media/upload", json=payload, headers=auth_headers)
    assert res.status_code == 201
    data = res.json()
    assert data["is_verified"] is True
    assert data["watermark_label"] == "LocalLens Verified"
    assert data["latitude"] == 12.97
    assert data["longitude"] == 77.59
    assert data["is_fuzzed"] is True
    assert "derived_hash" in data
    assert "url" in data
    assert "thumbnail_url" in data


@pytest.mark.asyncio
async def test_upload_media_endpoint_multipart(
    client: AsyncClient, auth_headers: dict[str, str]
):
    file_data = _make_jpeg_bytes()
    files = {"file": ("test.jpg", file_data, "image/jpeg")}
    data = {
        "is_in_app_camera": "false",
        "captured_lat": "12.9715",
        "captured_lng": "77.5945",
        "is_fuzzed": "false",
    }

    res = await client.post("/api/v1/media/upload", files=files, data=data, headers=auth_headers)
    assert res.status_code == 201
    res_json = res.json()
    assert res_json["is_verified"] is False
    assert res_json["watermark_label"] == "User Uploaded - Unverified"
    assert res_json["latitude"] == 12.9715
    assert res_json["longitude"] == 77.5945
    assert res_json["is_fuzzed"] is False

    # Test file retrieval endpoint (served bytes are the re-encoded JPEG)
    file_url = res_json["url"]
    file_res = await client.get(file_url)
    assert file_res.status_code == 200
    assert file_res.headers.get("x-content-type-options") == "nosniff"
    with Image.open(BytesIO(file_res.content)) as served:
        served.verify()


@pytest.mark.asyncio
async def test_upload_media_requires_auth(client: AsyncClient):
    """Unauthenticated uploads are rejected with 401."""
    b64_str = base64.b64encode(_make_jpeg_bytes()).decode("utf-8")
    res = await client.post("/api/v1/media/upload", json={"base64_payload": b64_str})
    assert res.status_code == 401


@pytest.mark.asyncio
async def test_upload_media_rejects_non_image(client: AsyncClient, auth_headers: dict[str, str]):
    """Non-image payloads are rejected with 400 invalid_image."""
    fake_bytes = b"this_is_definitely_not_an_image"
    b64_str = base64.b64encode(fake_bytes).decode("utf-8")
    res = await client.post(
        "/api/v1/media/upload", json={"base64_payload": b64_str}, headers=auth_headers
    )
    assert res.status_code == 400
    assert res.json().get("code") == "invalid_image"


@pytest.mark.asyncio
async def test_upload_media_rejects_oversize_base64(
    client: AsyncClient, auth_headers: dict[str, str], monkeypatch: pytest.MonkeyPatch
):
    """Base64 payloads larger than the max size are rejected with 413."""
    from app.features.media import service

    monkeypatch.setattr(service, "MAX_UPLOAD_BYTES", 1024)
    big_payload = base64.b64encode(b"x" * 2049).decode("utf-8")
    res = await client.post(
        "/api/v1/media/upload", json={"base64_payload": big_payload}, headers=auth_headers
    )
    assert res.status_code == 413
    assert res.json().get("code") == "media_too_large"


@pytest.mark.asyncio
async def test_upload_media_rejects_oversize_file(
    client: AsyncClient, auth_headers: dict[str, str], monkeypatch: pytest.MonkeyPatch
):
    """Multipart uploads larger than the max size are rejected with 413."""
    from app.features.media import service

    monkeypatch.setattr(service, "MAX_UPLOAD_BYTES", 1024)
    files = {"file": ("big.jpg", b"x" * 2049, "image/jpeg")}
    res = await client.post("/api/v1/media/upload", files=files, headers=auth_headers)
    assert res.status_code == 413
    assert res.json().get("code") == "media_too_large"
