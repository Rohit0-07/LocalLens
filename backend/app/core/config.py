from functools import lru_cache
from pathlib import Path
from typing import Self

from pydantic import model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

_BACKEND_DIR = Path(__file__).resolve().parent.parent.parent
_DEFAULT_DB_PATH = (_BACKEND_DIR / "locallens.db").as_posix()

_DEV_JWT_SECRET = "dev-secret-change-me-before-production-32b-min"
_DEV_ANON_HMAC_SECRET = "locallens-zero-retention-hmac-secret-key-32b"
_MIN_SECRET_LENGTH = 32


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

    jwt_secret: str = _DEV_JWT_SECRET
    jwt_algorithm: str = "HS256"
    access_token_ttl_minutes: int = 60 * 24 * 7

    anon_hmac_secret: str = _DEV_ANON_HMAC_SECRET

    otp_ttl_minutes: int = 5
    otp_master_code: str | None = None

    cors_origins: list[str] = ["*"]

    @model_validator(mode="after")
    def _validate_production_secrets(self) -> Self:
        if self.environment != "production":
            if self.otp_master_code is None:
                self.otp_master_code = "000000"
            return self
        for name, value, dev_default in (
            ("jwt_secret", self.jwt_secret, _DEV_JWT_SECRET),
            ("anon_hmac_secret", self.anon_hmac_secret, _DEV_ANON_HMAC_SECRET),
        ):
            if value == dev_default or len(value) < _MIN_SECRET_LENGTH:
                raise ValueError(
                    f"{name} must be set to a unique value of at least "
                    f"{_MIN_SECRET_LENGTH} characters in production"
                )
        if self.otp_master_code is not None:
            raise ValueError("otp_master_code must not be set in production")
        return self


@lru_cache
def get_settings() -> Settings:
    return Settings()
