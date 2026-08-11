import threading
import time
from collections import deque


class SlidingWindowRateLimiter:
    def __init__(self, max_requests: int, window_seconds: float) -> None:
        self._max_requests = max_requests
        self._window_seconds = window_seconds
        self._lock = threading.Lock()
        self._timestamps: dict[str, deque[float]] = {}

    def allow(self, key: str) -> bool:
        now = time.monotonic()
        with self._lock:
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
            timestamps = self._timestamps.get(key)
            if not timestamps:
                return self._max_requests
            while timestamps and now - timestamps[0] >= self._window_seconds:
                timestamps.popleft()
            if not timestamps:
                del self._timestamps[key]
                return self._max_requests
            return max(0, self._max_requests - len(timestamps))
