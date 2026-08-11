import base64

import pytest
from app.features.media.service import derive_media_hash, process_location, validate_verification
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_in_app_camera_media_verification(client: AsyncClient, auth_headers: dict[str, str]):
    """In-app camera capture with GPS lock sets is_verified=True and watermark 'LocalLens Verified'."""
    sample_bytes = b"in_app_camera_photo_data_with_gps_lock"
    b64_str = base64.b64encode(sample_bytes).decode("utf-8")

    payload = {
        "base64_payload": b64_str,
        "is_in_app_camera": True,
        "captured_lat": 12.971598,
        "captured_lng": 77.594562,
        "is_fuzzed": False,
    }

    res = await client.post("/api/v1/media/upload", json=payload, headers=auth_headers)
    assert res.status_code == 201
    data = res.json()
    assert data["is_verified"] is True
    assert data["watermark_label"] == "LocalLens Verified"
    assert data["latitude"] == 12.971598
    assert data["longitude"] == 77.594562

    # Unit verification logic check
    is_ver, label = validate_verification(is_in_app_camera=True, lat=12.9715, lng=77.5945)
    assert is_ver is True
    assert label == "LocalLens Verified"


@pytest.mark.asyncio
async def test_gallery_media_unverified(client: AsyncClient, auth_headers: dict[str, str]):
    """Gallery upload / missing GPS sets is_verified=False and watermark 'User Uploaded - Unverified'."""
    sample_bytes = b"gallery_picker_image_data"
    b64_str = base64.b64encode(sample_bytes).decode("utf-8")

    # Case 1: Gallery pick (is_in_app_camera = False) with GPS present
    payload_gallery = {
        "base64_payload": b64_str,
        "is_in_app_camera": False,
        "captured_lat": 12.9715,
        "captured_lng": 77.5945,
    }
    res1 = await client.post("/api/v1/media/upload", json=payload_gallery, headers=auth_headers)
    assert res1.status_code == 201
    data1 = res1.json()
    assert data1["is_verified"] is False
    assert data1["watermark_label"] == "User Uploaded - Unverified"

    # Case 2: In-app camera but missing GPS coordinates
    payload_no_gps = {
        "base64_payload": b64_str,
        "is_in_app_camera": True,
        "captured_lat": None,
        "captured_lng": None,
    }
    res2 = await client.post("/api/v1/media/upload", json=payload_no_gps, headers=auth_headers)
    assert res2.status_code == 201
    data2 = res2.json()
    assert data2["is_verified"] is False
    assert data2["watermark_label"] == "User Uploaded - Unverified"

    # Unit verification checks
    is_ver1, label1 = validate_verification(is_in_app_camera=False, lat=12.97, lng=77.59)
    assert is_ver1 is False
    assert label1 == "User Uploaded - Unverified"

    is_ver2, label2 = validate_verification(is_in_app_camera=True, lat=None, lng=None)
    assert is_ver2 is False
    assert label2 == "User Uploaded - Unverified"


@pytest.mark.asyncio
async def test_media_cryptographic_hash():
    """Verify SHA-256 hash consistency and tamper protection."""
    image_bytes = b"original_uncorrupted_camera_payload_12345"
    tampered_bytes = b"original_uncorrupted_camera_payload_12346"  # 1 byte changed

    user_id = "user_42"

    hash_original = derive_media_hash(image_bytes, user_id=user_id)
    hash_repeat = derive_media_hash(image_bytes, user_id=user_id)
    hash_tampered = derive_media_hash(tampered_bytes, user_id=user_id)
    hash_other_user = derive_media_hash(image_bytes, user_id="user_43")

    # Consistency check
    assert hash_original == hash_repeat
    assert len(hash_original) == 64

    # Tamper protection / Avalanche effect check
    assert hash_original != hash_tampered

    # User isolation check
    assert hash_original != hash_other_user


@pytest.mark.asyncio
async def test_media_location_fuzzing(client: AsyncClient):
    """Verify when is_fuzzed=True, latitude and longitude are rounded to 2 decimal places (~1.1 km precision)."""
    # Unit check
    lat_fuzzed, lng_fuzzed = process_location(12.9715987, 77.5945627, is_fuzzed=True)
    assert lat_fuzzed == 12.97
    assert lng_fuzzed == 77.59

    lat_exact, lng_exact = process_location(12.9715987, 77.5945627, is_fuzzed=False)
    assert lat_exact == 12.9715987
    assert lng_exact == 77.5945627

    # Endpoint check with is_fuzzed = True
    sample_bytes = b"fuzzed_media_location_content"
    b64_str = base64.b64encode(sample_bytes).decode("utf-8")

    res_fuzzed = await client.post(
        "/api/v1/media/upload",
        json={
            "base64_payload": b64_str,
            "is_in_app_camera": True,
            "captured_lat": 12.978912,
            "captured_lng": 77.591234,
            "is_fuzzed": True,
        },
    )
    assert res_fuzzed.status_code == 201
    data = res_fuzzed.json()
    assert data["latitude"] == 12.98
    assert data["longitude"] == 77.59
    assert data["is_fuzzed"] is True


@pytest.mark.asyncio
async def test_media_upload_invalid_format(client: AsyncClient):
    """Test 400 error on non-image file uploads or corrupted payload."""
    # Empty request
    res_empty = await client.post("/api/v1/media/upload", json={})
    assert res_empty.status_code == 400
    assert "No media file or base64 payload provided" in res_empty.json()["detail"]

    # Corrupted base64 string
    res_corrupt = await client.post(
        "/api/v1/media/upload",
        json={"base64_payload": "!!!invalid_base64_data!!!"},
    )
    assert res_corrupt.status_code == 400
    assert "Invalid base64 payload" in res_corrupt.json()["detail"]


@pytest.mark.asyncio
async def test_media_guest_access_restriction(client: AsyncClient, auth_headers: dict[str, str]):
    """Test upload rules for guest vs authenticated users."""
    sample_bytes = b"test_guest_vs_auth_media_content"
    b64_str = base64.b64encode(sample_bytes).decode("utf-8")

    # 1. Authenticated User upload
    res_auth = await client.post(
        "/api/v1/media/upload",
        json={
            "base64_payload": b64_str,
            "is_in_app_camera": True,
            "captured_lat": 12.97,
            "captured_lng": 77.59,
        },
        headers=auth_headers,
    )
    assert res_auth.status_code == 201
    auth_data = res_auth.json()
    assert auth_data["id"] is not None

    # 2. Guest User upload
    guest_res = await client.post("/api/v1/auth/guest")
    assert guest_res.status_code == 200
    guest_token = guest_res.json()["access_token"]
    guest_headers = {"Authorization": f"Bearer {guest_token}"}

    res_guest = await client.post(
        "/api/v1/media/upload",
        json={
            "base64_payload": b64_str,
            "is_in_app_camera": True,
            "captured_lat": 12.97,
            "captured_lng": 77.59,
        },
        headers=guest_headers,
    )
    assert res_guest.status_code == 201
    guest_data = res_guest.json()
    assert guest_data["id"] is not None

    # 3. Unauthenticated upload (no token provided)
    res_no_auth = await client.post(
        "/api/v1/media/upload",
        json={
            "base64_payload": b64_str,
            "is_in_app_camera": True,
            "captured_lat": 12.97,
            "captured_lng": 77.59,
        },
    )
    assert res_no_auth.status_code == 201
    no_auth_data = res_no_auth.json()
    assert no_auth_data["id"] is not None
