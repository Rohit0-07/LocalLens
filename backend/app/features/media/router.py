import asyncio
import base64
from datetime import datetime
from pathlib import Path

from fastapi import (
    APIRouter,
    File,
    Form,
    HTTPException,
    Request,
    UploadFile,
    status,
)
from fastapi.responses import FileResponse

from app.api.deps import CurrentUser, SessionDep
from app.core.exceptions import AppError
from app.features.media import service
from app.features.media.schemas import MediaDeleteOut, MediaUploadOut
from app.features.media.service import (
    create_media_record,
    find_media_path,
)

router = APIRouter()

_UPLOAD_CHUNK_SIZE = 1024 * 1024


async def _read_file_with_limit(file: UploadFile) -> bytes:
    """Read an UploadFile in chunks, rejecting payloads over the max size."""
    chunks: list[bytes] = []
    total = 0
    while chunk := await file.read(_UPLOAD_CHUNK_SIZE):
        total += len(chunk)
        if total > service.MAX_UPLOAD_BYTES:
            raise AppError(
                "Media exceeds the maximum allowed size of 10MB",
                status_code=413,
                code="media_too_large",
            )
        chunks.append(chunk)
    return b"".join(chunks)


@router.post(
    "/upload",
    response_model=MediaUploadOut,
    status_code=status.HTTP_201_CREATED,
)
async def upload_media(
    request: Request,
    db: SessionDep,
    current_user: CurrentUser,
    file: UploadFile | None = File(None),
    base64_payload: str | None = Form(None),
    is_in_app_camera: bool = Form(False),
    captured_lat: float | None = Form(None),
    captured_lng: float | None = Form(None),
    is_fuzzed: bool = Form(False),
    captured_at: datetime | None = Form(None),
) -> MediaUploadOut:
    image_bytes: bytes | None = None
    content_type = request.headers.get("content-type", "")

    if content_type.startswith("application/json"):
        try:
            body = await request.json()
            base64_payload = body.get("base64_payload") or body.get("payload") or body.get("file")
            is_in_app_camera = body.get("is_in_app_camera", is_in_app_camera)
            captured_lat = body.get("captured_lat", captured_lat)
            captured_lng = body.get("captured_lng", captured_lng)
            is_fuzzed = body.get("is_fuzzed", is_fuzzed)
            raw_captured_at = body.get("captured_at")
            if raw_captured_at:
                try:
                    captured_at = datetime.fromisoformat(str(raw_captured_at))
                except ValueError:
                    captured_at = None
        except Exception:
            pass

    if file:
        image_bytes = await _read_file_with_limit(file)
    elif base64_payload:
        clean_payload = base64_payload
        if "," in clean_payload:
            clean_payload = clean_payload.split(",", 1)[1]
        try:
            image_bytes = base64.b64decode(clean_payload)
        except Exception:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid base64 payload",
            ) from None
        if len(image_bytes) > service.MAX_UPLOAD_BYTES:
            raise AppError(
                "Media exceeds the maximum allowed size of 10MB",
                status_code=413,
                code="media_too_large",
            )

    if not image_bytes:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No media file or base64 payload provided",
        )

    user_id = current_user.id

    media = await create_media_record(
        db=db,
        image_bytes=image_bytes,
        is_in_app_camera=is_in_app_camera,
        captured_lat=captured_lat,
        captured_lng=captured_lng,
        is_fuzzed=is_fuzzed,
        user_id=user_id,
        captured_at=captured_at,
    )
    return MediaUploadOut.model_validate(media)


@router.delete(
    "/{media_id}",
    response_model=MediaDeleteOut,
    status_code=status.HTTP_200_OK,
)
async def delete_media(media_id: str, db: SessionDep, user: CurrentUser) -> MediaDeleteOut:
    if getattr(user, "is_guest", False):
        raise AppError(
            "Sign in required to delete media", status_code=403, code="guest_restricted"
        )
    media = await service.delete_media_record(db, media_id, user.id)
    if media is None:
        raise HTTPException(status_code=404, detail="Media not found")
    return MediaDeleteOut(success=True)


@router.get("/files/{filename}")
async def get_media_file(filename: str) -> FileResponse:
    clean_name = Path(filename).name
    if not clean_name or clean_name != filename:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid filename",
        )
    file_path = await asyncio.to_thread(find_media_path, clean_name)
    if not file_path or not file_path.exists():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="File not found")
    return FileResponse(file_path, headers={"X-Content-Type-Options": "nosniff"})