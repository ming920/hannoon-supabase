<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-07-01 | Updated: 2026-07-01 -->

# hannoon-supabase

## Purpose
The Supabase backend for hannoon: the **production source of truth** for the Postgres schema
(tables, enums, RLS, RPC functions, triggers, storage buckets) plus the `notify-onesignal` edge
function. The client app calls the RPC/REST surface here; the `hannoon-ai` pipeline writes/reads
the same tables. This repo owns schema — the AI side must mirror it (see `../AGENTS.md`).

## Key Files
| File | Description |
|------|-------------|
| `README.md` | Korean directory-structure overview (slightly stale vs. the real migration set) |
| `.gitignore` | Ignores local Supabase env/state |

## Subdirectories
| Directory | Purpose |
|-----------|---------|
| `supabase/` | Supabase project root: migrations, functions, tests, snippets, `config.toml`, `seed.sql` (see `supabase/AGENTS.md`) |
| `docs/` | `schema.md` (table/RPC reference) and `rls-policy.md` (RLS design) (see `docs/AGENTS.md`) |
| `.github/workflows/` | `ci.yaml` (spin up local Supabase, `db reset`, run pgTAP) and `deploy.yaml` (push migrations + deploy edge fn to dev) |

## For AI Agents

### Working In This Directory
- Respond in **Korean** (`.github/copilot-instructions.md`); when reviewing, include a
  `suggestion` block with the actual code change.
- **Migrations are forward-only and timestamp-named** (`YYYYMMDDHHMMSS_description.sql`). Never
  edit an applied migration — add a new one. CI runs `supabase db reset` from scratch, so the
  whole chain must replay cleanly.
- Keep `docs/schema.md` and `docs/rls-policy.md` in step with migrations; they are
  hand-maintained references, not generated.
- The schema here is consumed by `../hannoon-ai`. Before removing/renaming a column, check that
  pipeline's `src/db/` and `src/collector/storage.py`.

### Testing Requirements
- pgTAP tests live in `supabase/tests/`; CI runs them via `supabase test db` after `db reset`.
  Add/adjust a test when you change a function or trigger.

## Dependencies

### External
- Supabase CLI 2.95.4, Postgres 17.
- Extensions: `vector` (pgvector, 4096-dim), `pg_trgm`, `pg_net` — all in the `extensions` schema.
- OneSignal (push), Google OAuth (auth).

<!-- MANUAL: -->
