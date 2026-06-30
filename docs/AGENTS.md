<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-07-01 | Updated: 2026-07-01 -->

# docs

## Purpose
Hand-maintained reference docs for the schema and access control. Not generated — keep them in
step with `../supabase/migrations/` when the schema changes.

## Key Files
| File | Description |
|------|-------------|
| `schema.md` | Per-table column/constraint reference, enum types, extensions, triggers, RPC function signatures, storage buckets, and the `notify-onesignal` edge function contract |
| `rls-policy.md` | RLS design per table (profiles, subscriptions, notifications, viewed_events, internal AI tables, storage objects) and the revoke-then-grant baseline |

## For AI Agents

### Working In This Directory
- These docs are the human-facing schema reference; the **authoritative** schema is the migration
  chain. On any schema change, update the matching table/function entry here.
- `schema.md`'s `topics` table lists `parent_topic_id` (added 2026-07-01 alongside
  `../supabase/migrations/20260701120000_add_topics_parent_topic_id.sql`).
- `schema.md`'s `events` table lists `core_content` / `embedding_text` (added 2026-07-01;
  source migration `20260603120000`), and the duplicate/contradictory `get_articles_by_event`
  entry was removed — the canonical one uses `p_bias_type` ∈ `진보/중도/보수`.

## Dependencies

### Internal
- Mirrors `../supabase/migrations/`. Cross-referenced by `../../hannoon-ai` for the shared schema.

<!-- MANUAL: -->
