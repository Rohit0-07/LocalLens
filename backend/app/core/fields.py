from datetime import UTC, datetime
from typing import Annotated

from pydantic import PlainSerializer


def _as_utc(dt: datetime) -> datetime:
    """Normalize a datetime to a UTC-aware datetime for serialization.

    The app stores timestamps as naive UTC (`func.now()` / `_utc_now()`),
    which Pydantic would otherwise serialize without any offset — clients
    then parse them as local time and display skewed relative times.
    """
    if dt.tzinfo is None:
        return dt.replace(tzinfo=UTC)
    return dt.astimezone(UTC)


def _serialize_utc(dt: datetime) -> str:
    return _as_utc(dt).isoformat().replace("+00:00", "Z")


# Annotated alias for output fields so timestamps are always emitted as
# UTC (ISO-8601 "Z" form) regardless of how they were stored.
UTCDateTime = Annotated[datetime, PlainSerializer(_serialize_utc, return_type=str)]