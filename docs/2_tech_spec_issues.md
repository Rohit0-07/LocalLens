# Tech Spec Issues — F-B (map_heatmap_boundaries)

Itemized issues discovered while implementing `plans/F-B_map_heatmap_boundaries_plan.md`.
The plan is the operative input for F-B; `docs/2_tech_spec.md` is the locked F-03 spec.

## Issue 1 — `alembic upgrade head` fails on a fresh database (plan §2a infeasible)

**Severity:** medium (blocks `alembic upgrade head` on any DB not already
initialized by `Base.metadata.create_all`; does NOT affect pytest, which uses
`create_all`).

**Symptom:**

```
$ rm fresh.db && LOCALLENS_DATABASE_URL=sqlite+aiosqlite:////tmp/fresh.db uv run alembic upgrade head
sqlalchemy.exc.OperationalError: (sqlite3.OperationalError) no such table: wards
[SQL: ALTER TABLE wards ADD COLUMN boundary TEXT]
```

**Root cause:** the alembic chain never creates the `wards` table. The initial
revision `4bc740cb655c` only creates `otp_codes`, `users`, `issues`; every later
revision only alters `users`/`issues`. `wards` exists in the database solely via
`Base.metadata.create_all` (app startup, `seed.py`, tests). The plan §2a states
"real DBs get it via `alembic upgrade head`", which is false for any DB that has
not been `create_all`-initialized first.

**Resolution options (not implemented — no silent fix-forward):**
1. Add a new migration that creates the `wards` table (matching the `Ward`
   model) and make `c4d5e6f70819` depend on it; or fold table creation into
   `c4d5e6f70819` itself.
2. Declare alembic unsupported on fresh DBs and require `create_all` first
   (documented workflow change).

## Issue 2 — `alembic upgrade head` fails on the existing dev DB (duplicate column)

**Severity:** low (dev-environment bookkeeping only).

**Symptom:**

```
$ uv run alembic upgrade head
sqlalchemy.exc.OperationalError: (sqlite3.OperationalError) duplicate column name: boundary
[SQL: ALTER TABLE wards ADD COLUMN boundary TEXT]
```

**Root cause:** `backend/locallens.db` was (re)created by `create_all` after the
`Ward.boundary` model change, so the column already exists, while
`alembic_version` is still stamped at `b2c3d4e5f607`.

**Resolution applied (bookkeeping only, no code change):** `uv run alembic stamp
head` — the schema already matches head.

## Note — migration content itself

The migration `c4d5e6f70819_add_ward_boundary.py` is exactly what the plan
specifies (`batch_alter_table('wards') → add_column('boundary', sa.Text(),
nullable=True)`; downgrade drops it). No deviation was made to the migration.