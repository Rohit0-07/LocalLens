import base64

import pytest
from app.features.media.service import derive_media_hash, process_location, validate_verification
from app.main import app
from httpx import ASGITransport, AsyncClient


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


@pytest.fixture(autouse=True)
async def setup_db():
    await app.state.database.create_all()


@pytest.mark.asyncio
async def test_upload_media_endpoint_json():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        sample_bytes = b"test_image_bytes_for_media_pipeline"
        b64_str = base64.b64encode(sample_bytes).decode("utf-8")

        payload = {
            "base64_payload": b64_str,
            "is_in_app_camera": True,
            "captured_lat": 12.9715,
            "captured_lng": 77.5945,
            "is_fuzzed": True,
        }

        res = await ac.post("/api/v1/media/upload", json=payload)
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
async def test_upload_media_endpoint_multipart():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        file_data = b"raw_binary_jpeg_data_content"
        files = {"file": ("test.jpg", file_data, "image/jpeg")}
        data = {
            "is_in_app_camera": "false",
            "captured_lat": "12.9715",
            "captured_lng": "77.5945",
            "is_fuzzed": "false",
        }

        res = await ac.post("/api/v1/media/upload", files=files, data=data)
        assert res.status_code == 201
        res_json = res.json()
        assert res_json["is_verified"] is False
        assert res_json["watermark_label"] == "User Uploaded - Unverified"
        assert res_json["latitude"] == 12.9715
        assert res_json["longitude"] == 77.5945
        assert res_json["is_fuzzed"] is False

        # Test file retrieval endpoint
        file_url = res_json["url"]
        file_res = await ac.get(file_url)
        assert file_res.status_code == 200
        assert file_res.content == file_data
