import threading
import time
from collections import deque


class SlidingWindowRateLimiter:
    #: Upper bound on tracked keys; once reached, a lazy sweep evicts entries
    #: whose windows have fully elapsed so stale keys cannot grow memory.
    _MAX_TRACKED_KEYS = 10_000

    def __init__(self, max_requests: int, window_seconds: float) -> None:
        self._max_requests = max_requests
        self._window_seconds = window_seconds
        self._lock = threading.Lock()
        self._timestamps: dict[str, deque[float]] = {}

    def _evict_expired(self, now: float) -> None:
        """Drop keys with no live timestamps. Caller must hold self._lock."""
        stale = [
            key
            for key, timestamps in self._timestamps.items()
            if not timestamps or now - timestamps[-1] >= self._window_seconds
        ]
        for key in stale:
            del self._timestamps[key]

    def allow(self, key: str) -> bool:
        now = time.monotonic()
        with self._lock:
            if len(self._timestamps) >= self._MAX_TRACKED_KEYS:
                self._evict_expired(now)
            timestamps = self._timestamps.get(key)
            if timestamps is None:
                self._timestamps[key] = deque([now])
                return True
            while timestamps and now - timestamps[0] >= self._window_seconds:
                timestamps.popleft()
            if not timestamps:
                del self._timestamps[key]
                self._timestamps[key] = deque([now])
                return True
            if len(timestamps) >= self._max_requests:
                return False
            timestamps.append(now)
            return True

    def is_allowed(self, key: str) -> bool:
        return self.allow(key)

    def reset(self) -> None:
        with self._lock:
            self._timestamps.clear()

    def remaining(self, key: str) -> int:
        now = time.monotonic()
        with self._lock:
            if len(self._timestamps) >= self._MAX_TRACKED_KEYS:
                self._evict_expired(now)
            timestamps = self._timestamps.get(key)
            if not timestamps:
                return self._max_requests
            while timestamps and now - timestamps[0] >= self._window_seconds:
                timestamps.popleft()
            if not timestamps:
                del self._timestamps[key]
                return self._max_requests
            return max(0, self._max_requests - len(timestamps))
