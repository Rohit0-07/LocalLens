from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

_BACKEND_DIR = Path(__file__).resolve().parent.parent.parent
_DEFAULT_DB_PATH = (_BACKEND_DIR / "locallens.db").as_posix()


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=str(_BACKEND_DIR / ".env"),
        env_prefix="LOCALLENS_",
        extra="ignore",
    )

    app_name: str = "LocalLens API"
    version: str = "0.1.0"
    environment: str = "development"
    debug: bool = False

    database_url: str = f"sqlite+aiosqlite:///{_DEFAULT_DB_PATH}"

    jwt_secret: str = "dev-secret-change-me-before-production-32b-min"
    jwt_algorithm: str = "HS256"
    access_token_ttl_minutes: int = 60 * 24 * 7

    anon_hmac_secret: str = "locallens-zero-retention-hmac-secret-key-32b"

    otp_ttl_minutes: int = 5
    otp_master_code: str | None = None

    cors_origins: list[str] = ["*"]


@lru_cache
def get_settings() -> Settings:
    return Settings()
