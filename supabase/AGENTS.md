<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-07-01 | Updated: 2026-07-01 -->

# supabase

## Purpose
The Supabase project root. Holds the migration chain (schema source of truth), the edge function,
pgTAP tests, reusable SQL snippets, local config, and seed data. `supabase db reset` replays
`migrations/` then loads `seed.sql`; `supabase db push` applies migrations to a linked remote.

## Key Files
| File | Description |
|------|-------------|
| `config.toml` | Local CLI config: API/db ports, Postgres `major_version = 17`, `extra_search_path = [public, extensions]`, Google OAuth enabled, `[functions.notify-onesignal] verify_jwt = false` (public webhook self-auths via shared secret) |
| `seed.sql` | Dev seed data loaded after `db reset` (`[db.seed]` enabled) |
| `.gitignore` | Ignores local Supabase runtime artifacts |

## Subdirectories
| Directory | Purpose |
|-----------|---------|
| `migrations/` | Timestamp-ordered schema migrations — production source of truth (see `migrations/AGENTS.md`) |
| `functions/` | Deno edge functions (see `functions/AGENTS.md`) |
| `tests/` | pgTAP test files run by `supabase test db` (see `tests/AGENTS.md`) |
| `snippets/` | Reusable SQL fragments referenced by migrations (see `snippets/AGENTS.md`) |

## For AI Agents

### Working In This Directory
- `config.toml` documents intentional non-defaults: Google OAuth `redirect_uri`, the
  `additional_redirect_urls` allow-list (avoids post-OAuth 404s), and `verify_jwt = false` for
  `notify-onesignal` (the DB trigger authenticates with `WEBHOOK_SECRET` instead of a JWT).
- `extra_search_path` includes `extensions` so unqualified `vector` / `word_similarity` resolve.

### Testing Requirements
- `supabase start` → `supabase db reset` → `supabase test db` reproduces CI locally.

## Dependencies

### External
- Supabase CLI, Postgres 17, pgvector / pg_trgm / pg_net.

<!-- MANUAL: -->
