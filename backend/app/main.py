from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware

from app.api.router import api_router
from app.core.config import Settings, get_settings
from app.core.database import Database
from app.core.exceptions import AppError, app_error_handler, validation_error_handler
from app.core.logging import configure_logging
from app.core.ratelimit import SlidingWindowRateLimiter
from app.features.media.router import router as media_router


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    settings = app.state.settings
    if settings.environment == "development":
        await app.state.database.create_all()
        from app.core.data_migrator import run_data_migrations

        await run_data_migrations(app.state.database, settings)
    yield
    await app.state.database.dispose()


def create_app(settings: Settings | None = None) -> FastAPI:
    settings = settings or get_settings()
    configure_logging()
    app = FastAPI(title=settings.app_name, version=settings.version, lifespan=lifespan)
    app.state.settings = settings
    app.state.database = Database(settings.database_url)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=False,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    from app.features.issues import service as issues_service

    app.state.search_rate_limiter = SlidingWindowRateLimiter(max_requests=60, window_seconds=60)
    app.state.geo_rate_limiter = SlidingWindowRateLimiter(max_requests=60, window_seconds=60)
    app.state.rep_rate_limiter = SlidingWindowRateLimiter(max_requests=30, window_seconds=60)
    app.state.gamification_rate_limiter = SlidingWindowRateLimiter(
        max_requests=5, window_seconds=60
    )
    issues_service.flag_rate_limiter.reset()
    app.state.flag_rate_limiter = issues_service.flag_rate_limiter
    app.add_exception_handler(AppError, app_error_handler)
    app.add_exception_handler(RequestValidationError, validation_error_handler)  # type: ignore[arg-type]
    app.include_router(media_router, prefix="/api/v1/media", tags=["media"])
    app.include_router(api_router)
    return app


app = create_app()
