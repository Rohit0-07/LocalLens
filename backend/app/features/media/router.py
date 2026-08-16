import base64
from pathlib import Path
import typing

from fastapi import (
    APIRouter,
    Depends,
    File,
    Form,
    HTTPException,
    Request,
    UploadFile,
    status,
)
from fastapi.responses import FileResponse

from app.api.deps import SessionDep, get_optional_current_user
from app.features.media.schemas import MediaUploadOut
from app.features.media.service import (
    create_media_record,
    find_media_path,
)

router = APIRouter()


@router.post(
    "/upload",
    response_model=MediaUploadOut,
    status_code=status.HTTP_201_CREATED,
)
async def upload_media(
    request: Request,
    db: SessionDep,
    file: UploadFile | None = File(None),
    base64_payload: str | None = Form(None),
    is_in_app_camera: bool = Form(False),
    captured_lat: float | None = Form(None),
    captured_lng: float | None = Form(None),
    is_fuzzed: bool = Form(False),
    current_user: typing.Any = Depends(get_optional_current_user),
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
        except Exception:
            pass

    if file:
        image_bytes = await file.read()
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

    if not image_bytes:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No media file or base64 payload provided",
        )

    user_id = current_user.id if current_user else None

    media = await create_media_record(
        db=db,
        image_bytes=image_bytes,
        is_in_app_camera=is_in_app_camera,
        captured_lat=captured_lat,
        captured_lng=captured_lng,
        is_fuzzed=is_fuzzed,
        user_id=user_id,
    )
    return MediaUploadOut.model_validate(media)


@router.get("/files/{filename}")
async def get_media_file(filename: str) -> FileResponse:
    clean_name = Path(filename).name
    if not clean_name or clean_name != filename:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid filename",
        )
    file_path = find_media_path(clean_name)
    if not file_path or not file_path.exists():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="File not found")
    return FileResponse(file_path)
