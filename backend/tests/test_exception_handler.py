from app.core.exceptions import AppError, app_error_handler
from starlette.requests import Request


def _request(path: str = "/api/v1/auth/me") -> Request:
    scope = {
        "type": "http",
        "method": "GET",
        "path": path,
        "headers": [],
        "query_string": b"",
    }
    return Request(scope)


async def test_app_error_passes_through_details() -> None:
    response = await app_error_handler(_request(), AppError("Boom", status_code=418, code="boom"))
    assert response.status_code == 418
    assert response.body == b'{"detail":"Boom","code":"boom","error_code":"boom"}'


async def test_unhandled_exception_returns_generic_500_envelope() -> None:
    response = await app_error_handler(_request(), RuntimeError("secret internals leaked"))
    assert response.status_code == 500
    body = response.body.decode()
    assert "secret internals leaked" not in body
    assert '"code":"internal_error"' in body
