# ---- Toolchain ----
# Override with `make ... PY=python` if `uv` is not on PATH.
PY   ?= uv
APP_DIR := app
BACKEND_DIR := backend

.PHONY: help setup backend app seed sync-db sync-export check lint test gen format

# ---- Platform detection ----
# Recipes run under cmd.exe (or Git-Bash's sh) on Windows and /bin/sh on
# macOS/Linux, so `cd X && cmd` and `&&` chains are portable across all of
# them. `make` itself can be launched from PowerShell, cmd, or bash.
# $(OS) equals Windows_NT on native Windows; uname reports MINGW/MSYS when
# running GNU make from Git Bash — we handle both so echo quoting is right.
ifeq ($(OS),Windows_NT)
IS_WINDOWS := 1
else
UNAME_S := $(shell uname -s 2>/dev/null)
ifneq ($(findstring MINGW,$(UNAME_S))$(findstring MSYS,$(UNAME_S))$(findstring CYGWIN,$(UNAME_S)),)
IS_WINDOWS := 1
endif
endif

ifeq ($(IS_WINDOWS),1)
# cmd.exe: no quotes around the echo payload (it would print them literally).
HELP_ECHO = @echo $(1)
else
# POSIX sh: quote so multiple words are preserved as one argument.
HELP_ECHO = @echo "$(1)"
endif

help:
	$(call HELP_ECHO,LocalLens targets:)
	$(call HELP_ECHO,  make setup        install backend deps + app packages)
	$(call HELP_ECHO,  make backend      backend dev server (uvicorn --reload))
	$(call HELP_ECHO,  make sync-db      apply the team data snapshot from data_migrations/sync.sql)
	$(call HELP_ECHO,  make sync-export  write a team data snapshot to data_migrations/sync.sql)
	$(call HELP_ECHO,  make app          run the Flutter app)
	$(call HELP_ECHO,  make seed         wipe and reseed the dev database from seed/data)
	$(call HELP_ECHO,  make gen          freezed/json_serializable codegen)
	$(call HELP_ECHO,  make format       format both codebases)
	$(call HELP_ECHO,  make lint         ruff + flutter analyze)
	$(call HELP_ECHO,  make test         pytest + flutter test)
	$(call HELP_ECHO,  make check        lint + test)

sync-db:
	cd $(BACKEND_DIR) && $(PY) run python -m app.core.data_sync apply

sync-export:
	cd $(BACKEND_DIR) && $(PY) run python -m app.core.data_sync export

seed:
	cd $(BACKEND_DIR) && $(PY) run python seed.py

setup:
	cd $(BACKEND_DIR) && $(PY) sync
	cd $(APP_DIR) && flutter pub get

backend:
	cd $(BACKEND_DIR) && $(PY) run alembic upgrade head && $(PY) run uvicorn app.main:app --reload

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

