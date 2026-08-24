from app.core.logging import get_logger
from fastapi import Request
from fastapi.encoders import jsonable_encoder
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

logger = get_logger("locallens.errors")


class AppError(Exception):
    def __init__(
        self,
        message: str = "",
        *,
        status_code: int = 400,
        code: str = "app_error",
        error_code: str | None = None,
        detail: str | None = None,
    ) -> None:
        final_code = error_code or code
        final_message = detail or message
        self.message = final_message
        self.status_code = status_code
        self.code = final_code
        self.error_code = final_code
        super().__init__(final_message)


async def app_error_handler(request: Request, exc: Exception) -> JSONResponse:
    if isinstance(exc, AppError):
        return JSONResponse(
            status_code=exc.status_code,
            content={
                "detail": exc.message,
                "code": exc.code,
                "error_code": exc.error_code,
            },
        )
    logger.exception("Unhandled exception on %s %s", request.method, request.url.path)
    return JSONResponse(
        status_code=500,
        content={
            "detail": "Internal server error",
            "code": "internal_error",
            "error_code": "internal_error",
        },
    )


async def validation_error_handler(request: Request, exc: RequestValidationError) -> JSONResponse:
    if "/geo/" in request.url.path:
        detail = "; ".join(
            f"{'.'.join(str(loc) for loc in error.get('loc', ()))}: "
            f"{error.get('msg', 'Invalid input')}"
            for error in exc.errors()
        )
        return JSONResponse(
            status_code=422,
            content={
                "detail": detail,
                "code": "invalid_coordinates",
                "error_code": "invalid_coordinates",
            },
        )
    return JSONResponse(status_code=422, content={"detail": jsonable_encoder(exc.errors())})
