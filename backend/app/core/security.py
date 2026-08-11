import secrets
from datetime import UTC, datetime, timedelta

import bcrypt
import jwt
from app.core.config import Settings

_MAX_BCRYPT_BYTES = 72


def _truncate(secret: str) -> bytes:
    return secret.encode("utf-8")[:_MAX_BCRYPT_BYTES]


def hash_secret(secret: str) -> str:
    return bcrypt.hashpw(_truncate(secret), bcrypt.gensalt()).decode("utf-8")


def verify_secret(secret: str, hashed: str) -> bool:
    try:
        return bcrypt.checkpw(_truncate(secret), hashed.encode("utf-8"))
    except ValueError:
        return False


def generate_otp(length: int = 6) -> str:
    return f"{secrets.randbelow(10**length):0{length}d}"


def create_access_token(subject: str, settings: Settings) -> str:
    now = datetime.now(UTC)
    payload = {
        "sub": subject,
        "iat": now,
        "exp": now + timedelta(minutes=settings.access_token_ttl_minutes),
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def decode_access_token(token: str, settings: Settings) -> str:
    payload = jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])
    return str(payload["sub"])


def derive_anonymous_identity(user_id: int | str, secret: str) -> str:
    import hashlib
    import hmac

    h = hmac.new(secret.encode("utf-8"), str(user_id).encode("utf-8"), hashlib.sha256)
    return f"anon_{h.hexdigest()[:16]}"


def derive_anon_id(user_identifier: str, hmac_secret: str) -> str:
    import hashlib
    import hmac

    h = hmac.new(hmac_secret.encode("utf-8"), user_identifier.encode("utf-8"), hashlib.sha256)
    return f"anon_{h.hexdigest()[:16]}"
