import hashlib
import uuid
from io import BytesIO
from pathlib import Path

from sqlalchemy.ext.asyncio import AsyncSession

from app.features.media.models import Media

UPLOAD_DIR = Path("uploads/media")
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)


def find_media_path(filename: str) -> Path | None:
    """Safely find a media file in upload or seed directories without path traversal."""
    clean_name = Path(filename).name
    if not clean_name or clean_name != filename:
        return None

    candidates = [
        UPLOAD_DIR / clean_name,
        Path("uploads/media") / clean_name,
        Path("backend/uploads/media") / clean_name,
        Path(__file__).resolve().parent.parent.parent.parent / "uploads" / "media" / clean_name,
        Path(__file__).resolve().parent.parent.parent / "uploads" / "media" / clean_name,
        Path(__file__).resolve().parent.parent.parent.parent / "seed" / "media" / clean_name,
        Path(__file__).resolve().parent.parent.parent / "seed" / "media" / clean_name,
    ]
    for c in candidates:
        if c.exists() and c.is_file():
            return c
    return None


def derive_media_hash(image_bytes: bytes, user_id: str | int | None = None) -> str:
    """Compute cryptographic media hash derive_media_hash(image_bytes, user_id)."""
    hasher = hashlib.sha256(image_bytes)
    if user_id is not None:
        hasher.update(str(user_id).encode("utf-8"))
    return hasher.hexdigest()


def process_location(
    lat: float | None, lng: float | None, is_fuzzed: bool
) -> tuple[float | None, float | None]:
    """Fuzz location coordinates if requested by rounding to 2 decimal places."""
    if lat is None or lng is None:
        return None, None
    if is_fuzzed:
        return round(lat, 2), round(lng, 2)
    return lat, lng


def validate_verification(
    is_in_app_camera: bool, lat: float | None, lng: float | None
) -> tuple[bool, str]:
    """Validate EXIF/camera source & GPS lock for media verification."""
    is_verified = bool(is_in_app_camera and lat is not None and lng is not None)
    watermark_label = "LocalLens Verified" if is_verified else "User Uploaded - Unverified"
    return is_verified, watermark_label


async def create_media_record(
    db: AsyncSession,
    image_bytes: bytes,
    is_in_app_camera: bool = False,
    captured_lat: float | None = None,
    captured_lng: float | None = None,
    is_fuzzed: bool = False,
    user_id: str | int | None = None,
) -> Media:
    """Process uploaded media bytes, compute hash, handle fuzzing/verification, and save record."""
    media_id = str(uuid.uuid4())
    derived_hash = derive_media_hash(image_bytes, user_id)

    lat, lng = process_location(captured_lat, captured_lng, is_fuzzed)
    is_verified, watermark_label = validate_verification(
        is_in_app_camera, captured_lat, captured_lng
    )

    filename = f"{media_id}.jpg"
    thumb_filename = f"thumb_{media_id}.jpg"

    file_path = UPLOAD_DIR / filename
    thumb_path = UPLOAD_DIR / thumb_filename

    file_path.write_bytes(image_bytes)

    try:
        from PIL import Image  # type: ignore

        img = Image.open(BytesIO(image_bytes))
        if img.mode in ("RGBA", "P"):
            img = img.convert("RGB")
        img.thumbnail((300, 300))
        img.save(thumb_path, format="JPEG")
    except Exception:
        thumb_path.write_bytes(image_bytes)

    url = f"/api/v1/media/files/{filename}"
    thumbnail_url = f"/api/v1/media/files/{thumb_filename}"

    media = Media(
        id=media_id,
        user_id=str(user_id) if user_id is not None else None,
        url=url,
        thumbnail_url=thumbnail_url,
        is_verified=is_verified,
        watermark_label=watermark_label,
        derived_hash=derived_hash,
        latitude=lat,
        longitude=lng,
        is_fuzzed=is_fuzzed,
        is_in_app_camera=is_in_app_camera,
    )

    db.add(media)
    await db.commit()
    await db.refresh(media)
    return media
