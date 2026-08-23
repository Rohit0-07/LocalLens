import hashlib
import uuid
from datetime import UTC, datetime
from io import BytesIO
from pathlib import Path

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import AppError
from app.features.media.models import Media

_BACKEND_DIR = Path(__file__).resolve().parent.parent.parent.parent
UPLOAD_DIR = _BACKEND_DIR / "uploads" / "media"
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)


def find_media_path(filename: str) -> Path | None:
    """Safely find a media file in upload or seed directories without path traversal."""
    clean_name = Path(filename).name
    if not clean_name or clean_name != filename:
        return None

    candidates = [
        UPLOAD_DIR / clean_name,
        _BACKEND_DIR / "seed" / "media" / clean_name,
        Path(__file__).resolve().parent.parent.parent.parent / "seed" / "media" / clean_name,
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


def _to_dms(value: float) -> tuple[int, int, int]:
    """Convert decimal degrees to a (degrees, minutes, seconds) integer tuple.

    Each component is scaled by 1_000_000 so it can be stored directly as an
    EXIF rational ``(component, 1_000_000)`` with 1e-6 degree precision.
    """
    value = abs(value)
    degrees = int(value)
    minutes_float = (value - degrees) * 60
    minutes = int(minutes_float)
    seconds = round((minutes_float - minutes) * 60, 6)
    return degrees * 1_000_000, minutes * 1_000_000, int(seconds * 1_000_000)


def _dms_rationals(value: float) -> tuple[tuple[int, int], tuple[int, int], tuple[int, int]]:
    """Return the DMS components of ``value`` as EXIF rational tuples."""
    degrees, minutes, seconds = _to_dms(value)
    return (
        (degrees, 1_000_000),
        (minutes, 1_000_000),
        (seconds, 1_000_000),
    )


def embed_exif_gps(
    image_bytes: bytes,
    lat: float | None,
    lng: float | None,
    captured_at: datetime | None = None,
) -> bytes:
    """Embed GPS EXIF metadata into a JPEG payload.

    When both ``lat`` and ``lng`` are provided, re-encodes the image with a
    GPSInfo IFD (EXIF tag 34853) containing ``GPSLatitudeRef``/``GPSLatitude``,
    ``GPSLongitudeRef``/``GPSLongitude`` (DMS rationals, 6-decimal precision),
    ``GPSTimeStamp`` and ``DateTimeOriginal`` (from ``captured_at``). Returns
    the original bytes unchanged on any failure so a non-JPEG payload never
    raises.
    """
    if lat is None or lng is None:
        return image_bytes
    try:
        from PIL import Image
        from PIL.ExifTags import GPS, IFD
        from PIL.TiffImagePlugin import IFDRational

        opened = Image.open(BytesIO(image_bytes))
        img = opened.convert("RGB") if opened.mode in ("RGBA", "P") else opened

        gps_ifd: dict[int, object] = {
            GPS.GPSLatitudeRef: "N" if lat >= 0 else "S",
            GPS.GPSLatitude: tuple(
                IFDRational(num, den) for num, den in _dms_rationals(lat)
            ),
            GPS.GPSLongitudeRef: "E" if lng >= 0 else "W",
            GPS.GPSLongitude: tuple(
                IFDRational(num, den) for num, den in _dms_rationals(lng)
            ),
        }
        if captured_at is not None:
            captured_utc = captured_at.astimezone(UTC)
            gps_ifd[GPS.GPSTimeStamp] = (
                IFDRational(captured_utc.hour, 1),
                IFDRational(captured_utc.minute, 1),
                IFDRational(captured_utc.second, 1),
            )

        exif = img.getexif()
        exif[IFD.GPSInfo] = gps_ifd
        if captured_at is not None:
            exif[0x0132] = captured_at.astimezone(UTC).strftime("%Y:%m:%d %H:%M:%S")

        output = BytesIO()
        img.save(output, format="JPEG", exif=exif)
        return output.getvalue()
    except Exception:
        return image_bytes


async def create_media_record(
    db: AsyncSession,
    image_bytes: bytes,
    is_in_app_camera: bool = False,
    captured_lat: float | None = None,
    captured_lng: float | None = None,
    is_fuzzed: bool = False,
    user_id: str | int | None = None,
    captured_at: datetime | None = None,
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

    file_bytes = embed_exif_gps(image_bytes, captured_lat, captured_lng, captured_at)
    file_path.write_bytes(file_bytes)

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
        captured_at=captured_at,
    )

    db.add(media)
    await db.commit()
    await db.refresh(media)
    return media


async def delete_media_record(
    db: AsyncSession,
    media_id: str,
    user_id: int | str,
) -> Media | None:
    """Soft-delete a media record owned by the given user.

    Returns ``None`` when the record does not exist or is already deleted.
    Raises ``AppError(403)`` when the record belongs to another user and
    ``AppError(409)`` when the media is attached to a live (non-hidden) issue.
    """
    media = await db.get(Media, media_id)
    if media is None or media.deleted_at is not None:
        return None
    if media.user_id != str(user_id):
        raise AppError(
            "Not authorized to delete this media", status_code=403, code="forbidden"
        )
    if media.issue_id is not None:
        from app.features.issues.models import Issue

        issue = await db.get(Issue, media.issue_id)
        if issue is not None and not issue.is_hidden:
            raise AppError(
                "This photo is attached to a published report",
                status_code=409,
                code="media_linked_to_issue",
            )
    media.deleted_at = datetime.now(UTC)
    await db.commit()
    await db.refresh(media)
    return media