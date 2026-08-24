import pytest
from app.core.config import Settings

_PROD_SECRETS = {
    "jwt_secret": "a" * 32,
    "anon_hmac_secret": "b" * 32,
}


def _settings(**overrides: str) -> Settings:
    values = {"environment": "production", **_PROD_SECRETS, **overrides}
    return Settings(**values)


def test_production_rejects_default_jwt_secret() -> None:
    with pytest.raises(ValueError, match="jwt_secret"):
        _settings(jwt_secret="dev-secret-change-me-before-production-32b-min")


def test_production_rejects_short_jwt_secret() -> None:
    with pytest.raises(ValueError, match="jwt_secret"):
        _settings(jwt_secret="too-short")


def test_production_rejects_default_anon_hmac_secret() -> None:
    with pytest.raises(ValueError, match="anon_hmac_secret"):
        _settings(anon_hmac_secret="locallens-zero-retention-hmac-secret-key-32b")


def test_production_rejects_short_anon_hmac_secret() -> None:
    with pytest.raises(ValueError, match="anon_hmac_secret"):
        _settings(anon_hmac_secret="also-short")


def test_production_rejects_otp_master_code() -> None:
    with pytest.raises(ValueError, match="otp_master_code"):
        _settings(otp_master_code="000000")


def test_production_accepts_strong_secrets_and_no_master_otp() -> None:
    settings = _settings(otp_master_code=None)
    assert settings.environment == "production"


def test_development_allows_defaults_and_master_otp() -> None:
    settings = Settings(environment="development", otp_master_code="000000")
    assert settings.environment == "development"
