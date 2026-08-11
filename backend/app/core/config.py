from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_prefix="LOCALLENS_",
        extra="ignore",
    )

    app_name: str = "LocalLens API"
    version: str = "0.1.0"
    environment: str = "development"
    debug: bool = False

    database_url: str = "sqlite+aiosqlite:///./locallens.db"

    jwt_secret: str = "dev-secret-change-me-before-production-32b-min"
    jwt_algorithm: str = "HS256"
    access_token_ttl_minutes: int = 60 * 24 * 7

    anon_hmac_secret: str = "locallens-zero-retention-hmac-secret-key-32b"

    otp_ttl_minutes: int = 5
    otp_master_code: str | None = None


@lru_cache
def get_settings() -> Settings:
    return Settings()
