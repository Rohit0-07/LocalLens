from fastapi import Request
from fastapi.encoders import jsonable_encoder
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse


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
    error = exc if isinstance(exc, AppError) else AppError(str(exc))
    return JSONResponse(
        status_code=error.status_code,
        content={"detail": error.message, "code": error.code, "error_code": error.error_code},
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
