from fastapi import APIRouter

from app.api.deps import SessionDep, SettingsDep
from app.api.health import router as health_router
from app.features.auth import service as auth_service
from app.features.auth.router import router as auth_router
from app.features.auth.schemas import PublicUserProfileOut
from app.features.feed.router import router as feed_router
from app.features.gamification.router import router as gamification_router
from app.features.geo.router import router as geo_router
from app.features.issues.router import admin_router, wins_router
from app.features.issues.router import router as issues_router
from app.features.notifications.router import router as notifications_router
from app.features.representatives.router import router as representatives_router
from app.features.search.router import router as search_router
from app.features.wards.router import router as wards_router

users_router = APIRouter(prefix="/users", tags=["users"])


@users_router.get("/{user_id}", response_model=PublicUserProfileOut)
async def get_user_profile_alias(
    user_id: int,
    session: SessionDep,
    settings: SettingsDep,
) -> PublicUserProfileOut:
    return await auth_service.get_public_user_profile(
        session,
        user_id=user_id,
        secret=settings.jwt_secret,
    )


api_router = APIRouter(prefix="/api/v1")
api_router.include_router(health_router)
api_router.include_router(auth_router, prefix="/auth", tags=["auth"])
api_router.include_router(users_router)
api_router.include_router(issues_router, prefix="/issues", tags=["issues"])
api_router.include_router(wins_router)
api_router.include_router(feed_router, prefix="/feed", tags=["feed"])
api_router.include_router(admin_router)
api_router.include_router(notifications_router, prefix="/notifications", tags=["notifications"])
api_router.include_router(search_router, prefix="/search", tags=["search"])
api_router.include_router(representatives_router, tags=["representatives"])
api_router.include_router(gamification_router, prefix="/gamification", tags=["gamification"])
api_router.include_router(wards_router, prefix="/wards", tags=["wards"])
api_router.include_router(geo_router)
