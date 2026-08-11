# LocalLens Backend

FastAPI + SQLAlchemy 2 (async) API for LocalLens, managed with [uv](https://docs.astral.sh/uv/).

## Layout

```
backend/
├── app/
│   ├── main.py            application factory (create_app) + lifespan
│   ├── api/               transport layer: router aggregation, deps, health
│   ├── core/              cross-cutting: config, database, security, exceptions, logging
│   └── features/          one folder per domain capability
│       ├── auth/          models / schemas / service / router — OTP + JWT
│       └── issues/        models / schemas / service / router — geo-anchored reports
└── tests/                 pytest suite mirroring features/
```

## Rules of the structure

- A feature owns its models, schemas, business logic (service) and HTTP surface (router).
  Files stay small: `service.py` holds logic, `router.py` only wires HTTP to the service.
- `core/` never imports from `features/` (features depend on core, never the reverse).
- Database sessions and auth come from `app/api/deps.py` (`SessionDep`, `CurrentUser`).
- All datetimes are UTC-naive; anything else will produce timezone bugs.
- Consumers talk to the API through schemas, never ORM objects.

## Commands

```sh
uv run uvicorn app.main:app --reload        # dev server on :8000
uv run pytest                               # tests
uv run ruff check . && uv run ruff format --check .
uv run mypy app
uv run alembic revision --autogenerate -m "..."   # schema evolution
uv run alembic upgrade head
```

## Configuration

Copies of `.env.example` become `.env`; every setting is overridable via
environment variables prefixed `LOCALLENS_`. Dev defaults are safe for local
work: SQLite file database, no SMS provider (OTP is logged to the console
outside production), `OTP_MASTER_CODE=000000` can be set for end-to-end testing.

## Next steps (foundation gaps, by design)

- SMS provider integration for OTP delivery in production.
- Ward/geofence routing, duplicate guard, and the escalation ladder.
- Real password-less rep verification and the anonymous-identity (anon-ID) split.