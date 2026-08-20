PY ?= uv
APP_DIR := app
BACKEND_DIR := backend

.PHONY: help setup backend app seed sync-db check lint test gen format

ifeq ($(OS),Windows_NT)
HELP_ECHO = @echo $(1)
else
HELP_ECHO = @echo "$(1)"
endif

help:
	$(call HELP_ECHO,LocalLens targets:)
	$(call HELP_ECHO,  make setup       install backend deps + app packages)
	$(call HELP_ECHO,  make backend     backend dev server (uvicorn --reload))
	$(call HELP_ECHO,  make sync-db     sync database content from data_migrations)
	$(call HELP_ECHO,  make app         run the Flutter app)
	$(call HELP_ECHO,  make seed        wipe and reseed the dev database from seed/data)
	$(call HELP_ECHO,  make gen         freezed/json_serializable codegen)
	$(call HELP_ECHO,  make format      format both codebases)
	$(call HELP_ECHO,  make lint        ruff + flutter analyze)
	$(call HELP_ECHO,  make test        pytest + flutter test)
	$(call HELP_ECHO,  make check       lint + test)

sync-db:
	cd $(BACKEND_DIR) && $(PY) run python -m app.core.data_migrator --apply

seed:
	cd $(BACKEND_DIR) && $(PY) run python seed.py

setup:
	cd $(BACKEND_DIR) && $(PY) sync
	cd $(APP_DIR) && flutter pub get

backend:
	cd $(BACKEND_DIR) && $(PY) run alembic upgrade head && $(PY) run python -m app.core.data_migrator && $(PY) run uvicorn app.main:app --reload

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

