# LocalLens

A hyper-local civic issues platform. Residents report potholes, streetlights, and
public services from their phone; the feed is filtered to the user's own neighbourhood,
authorities are notified, and issues move through an escalation ladder until resolved.

This repository is a **monorepo** with a Python/FastAPI backend and a Flutter app, both
kept small and feature-first. The repository also carries a Spec-Driven Development
harness (OpenCode / Claude Code / Antigravity) — see [`pipeline.md`](pipeline.md) and
`AGENTS.md` for that.

## Repo layout

```
LocalLens/
├── backend/            FastAPI + SQLAlchemy 2 (async) API, managed by uv
│   ├── app/
│   │   ├── api/        transport: router aggregation, deps, health
│   │   ├── core/       config, database, security, exceptions, logging
│   │   └── features/   auth (OTP + JWT), issues (geo-anchored reports)
│   ├── seed.py         loads seed/data into the database (see seed/)
│   └── tests/          pytest suite mirroring features/
├── app/                Flutter client (org in.locallens)
│   ├── lib/
│   │   ├── core/       config, storage, theme, network, router
│   │   └── features/   auth, feed, compose, map, inbox, profile, ...
│   └── test/           flutter_test + Riverpod container tests
└── seed/               demo data (JSON per type) + issue images
```

## Quickstart

### Backend (uv)

```sh
cd backend
cp .env.example .env
uv sync
uv run alembic upgrade head
uv run python seed.py             # or `make seed`: load demo data + images
uv run uvicorn app.main:app --reload    # API on :8000
```

### App (Flutter)

```sh
cd app
flutter pub get
dart run build_runner build             # freezed / json_serializable codegen
flutter run
```

## Checks

```sh
make check          # backend ruff+mypy+pytest and app analyze+test
```

Backend details: `backend/README.md`. App details: `app/README.md`.
Design docs: `LocalLens_App_Info.md`, `LocalLens_Feature_Checklist.md`.

## Status

- **Backend**: auth (OTP request/verify + JWT), issues (create / feed / radius search),
  async SQLAlchemy + Alembic, full test suite green, ruff + mypy strict clean.
- **App**: scaffolded with Riverpod 2.6, go_router 17 (4-tab shell + compose FAB),
  dio client with auth interceptor, hive_ce local storage, freezed models,
  auth + feed + compose flows with screens, 17 tests green, `flutter analyze` clean.
- **Known ecosystem pins** (do not bump casually): riverpod `2.6.1`, freezed
  `4.0.0-dev.3`, build_runner `2.15.1`, go_router `17.4.0`, dio `5.11.0` —
  see `app/pubspec.yaml` for the conflict notes.

## Next steps

- SMS provider for production OTP delivery; rep verification; anon-ID split.
- Ward/geofence routing, duplicate guard, escalation ladder, notifications.
- Compose-to-backend wiring, map tab, issue detail with photos.
