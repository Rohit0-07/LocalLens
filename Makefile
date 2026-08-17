PY ?= uv
APP_DIR := app
BACKEND_DIR := backend

.PHONY: help setup backend app seed check lint test gen format

help:
	@echo "LocalLens targets:"
	@echo "  make setup       install backend deps + app packages"
	@echo "  make backend     backend dev server (uvicorn --reload)"
	@echo "  make app         run the Flutter app"
	@echo "  make seed        wipe and reseed the dev database from seed/data"
	@echo "  make gen         freezed/json_serializable codegen"
	@echo "  make format      format both codebases"
	@echo "  make lint        ruff + flutter analyze"
	@echo "  make test        pytest + flutter test"
	@echo "  make check       lint + test"

seed:
	cd $(BACKEND_DIR) && $(PY) run python seed.py

setup:
	cd $(BACKEND_DIR) && $(PY) sync
	cd $(APP_DIR) && flutter pub get

backend:
	cd $(BACKEND_DIR) && source .venv/bin/activate && $(PY) run alembic upgrade head && $(PY) run uvicorn app.main:app --reload

app:
	cd $(APP_DIR) && flutter run

gen:
	cd $(APP_DIR) && dart run build_runner build

format:
	cd $(BACKEND_DIR) && $(PY) run ruff format .
	cd $(APP_DIR) && dart format lib test

lint:
	cd $(BACKEND_DIR) && $(PY) run ruff check . && $(PY) run mypy app
	cd $(APP_DIR) && flutter analyze

test:
	cd $(BACKEND_DIR) && $(PY) run pytest
	cd $(APP_DIR) && flutter test

check: lint test
