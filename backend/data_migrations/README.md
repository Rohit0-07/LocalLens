# LocalLens Team Data Sync

This folder is **transient**. It holds one data snapshot per team hand-off so
every team member's local SQLite dev database sees the same **data** (schema
changes live in `backend/alembic/`). Database files are git-ignored
(`*.db`), so rows are shared by exporting them to a committed `.sql` file.

## The one-snapshot flow

Strict turn-taking keeps every database identical after each hand-off, so a
full snapshot is always safe to apply.

| Step | Who | Command | What happens |
|------|-----|---------|--------------|
| 0 | new teammate | `make setup` → `make backend` → `make seed` | Baseline schema + seed demo data only |
| 1 | sender (has new data) | `make sync-export` | Writes `sync.sql` (full idempotent snapshot) + bundles media into `media/` |
| 2 | sender | `git commit` + `git push` | Pushes the snapshot |
| 3 | receiver | `git pull` | Pulls the snapshot |
| 4 | receiver | `make backend` (or `make sync-db`) | Startup auto-applies it, then deletes `sync.sql` and `media/` |

> Apply is **transactional and idempotent**: it upserts (`INSERT ...
> ON CONFLICT DO UPDATE`) every row in foreign-key-safe order, and rolls back
> completely on the first error. If it fails, `sync.sql` is left in place so
> the reason can be investigated. Applying twice changes nothing.

## Commands

```sh
# Sender: dump your whole DB to backend/data_migrations/sync.sql (+ media/)
make sync-export
# or: cd backend && uv run python -m app.core.data_sync export

# Receiver: apply the pulled snapshot (also runs automatically at startup)
make sync-db
# or: cd backend && uv run python -m app.core.data_sync apply
```

## Rules (so hand-offs stay clean)

- **One snapshot at a time.** Export, push, have everyone apply, then start
  again. Never export while another snapshot is in flight.
- **Never hand-edit `sync.sql`.** It is machine-generated. If your changes
  are more than row data (new columns, constraints), they belong in an
  Alembic migration.
- **Baseline demo data stays in `seed/`.** This folder only carries the row
  mutations that happened since the last hand-off.
- **`sync.sql` and `media/` are deleted after a successful apply.** If they
  re-appear in `git status`, someone exported but nobody applied yet.