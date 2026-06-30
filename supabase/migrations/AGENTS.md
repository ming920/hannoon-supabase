<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-07-01 | Updated: 2026-07-01 -->

# migrations

## Purpose
Forward-only, timestamp-named (`YYYYMMDDHHMMSS_description.sql`) Postgres migrations — the
**production source of truth** for hannoon's schema. `supabase db reset` (CI) replays the entire
chain from empty; `supabase db push` (deploy) applies new ones to the linked remote. This is the
schema that **both** the client app and the `../../../hannoon-ai` pipeline depend on.

## Migration map (by area)
| Area | Key migrations |
|------|----------------|
| Baseline / privileges | `20260501105142_remote_schema.sql`, `20260501120000_revoke_default_privileges.sql` (revoke all default `anon`/`authenticated` grants, then grant explicitly) |
| Auth / profiles | `20260502135945_create_profiles_table.sql`, `20260509143459_update_profiles_rls_and_get_profile.sql`, `20260529120000_create_delete_user_function.sql` |
| Core content | `20260503061604_create_articles_table.sql`, `20260503082036_create_topics_and_events_table.sql`, `20260508163802_create_event_articles_table.sql`, `20260508192620_create_abusing_articles_table.sql`, `20260509030000_creat_feeds_table.sql` |
| AI pipeline tables | `20260509100000_create_article_ai_results_table.sql`, `20260509112000_creat_article_jobs_table.sql`, `20260525170000_add_unique_article_id_to_article_jobs.sql` |
| Embeddings / vector | `20260525120000_add_embeddings_and_topic_causes.sql` (768-dim + `topic_causes`), `20260612120000_change_embeddings_to_4096_dimensions.sql` (→ 4096, clears stored vectors) |
| Schema evolution for AI | `20260509091459_rename_events_columns...` (`prev_event`→`prev_event_id`, `next_event`→`next_event_id`), `20260601120000_add_reason_columns.sql`, `20260602120000_add_article_id_unique.sql`, `20260603120000_add_core_content_columns.sql` (`events.core_content`/`embedding_text`, `articles.core_content`), `20260525160000_alter_articles_guid_to_text.sql`, `20260701120000_add_topics_parent_topic_id.sql` (subtopic hierarchy self-FK) |
| List/RPC functions | `20260507120000_create_list_query_functions.sql`, `20260521000000_update_get_topic_add_summary.sql`, `20260604120000_fix_get_events_topic_id_filter...`, `20260609120000_add_topic_title_to_get_events.sql`, `20260622120000_order_get_events_get_topics_by_created_at.sql` |
| Subscriptions / notifications | `20260506181422_create_subscriptions_table.sql`, `20260512070332_create_notifications_table.sql`, `20260526000000_notify_onesignal_webhook.sql`, `20260621140000_onesignal_config_table.sql` |
| Viewed events | `20260530120000_create_viewed_events_table.sql`, `20260605120000_fix_viewed_events_cascade.sql` |
| Triggers / counts | `20260604..._add_event_assigned`, `20260605130000_fix_increment_abusing_count.sql`, `20260525150000_fix_get_event_anon_subscription.sql` |
| Storage / misc | `20260509120000_create_storage_buckets.sql`, `20260605140000_set_timezone_seoul.sql` |

## Schema-sync note: `topics.parent_topic_id` (resolved 2026-07-01)
`../../../hannoon-ai`'s 2-level subtopic hierarchy needs a self-referential
`topics.parent_topic_id` column (used by `src/db/topics.py`, `src/db/topic_causes.py`
`roots_only`/`parent_topic_id` scoping, `src/topic_classifier/pipeline.py` `_assign_hierarchical`).
It was previously missing here and is now added by
`20260701120000_add_topics_parent_topic_id.sql` (column + self-FK `ON DELETE SET NULL` +
`idx_topics_parent_topic_id`), ported from `hannoon-ai/migrations/0001_topics_parent_topic_id.sql`.
`docs/schema.md` topics table is updated to match. Run `supabase db push` to apply it to the
linked remote before enabling `subtopics_enabled` in production. The list RPCs (`get_topics`,
`get_events`) still return a flat list and are unaffected; revisit them only if the client needs to
surface the hierarchy.

## For AI Agents

### Working In This Directory
- **Never edit an applied migration** — add a new timestamped one. The whole chain must replay
  cleanly under `supabase db reset`.
- `events.embedding`, `articles.embedding`, `topic_causes.cause_embedding` are `extensions.vector(4096)`.
  Changing embedding dimensions means a new `ALTER ... TYPE vector(N) USING NULL` migration **and**
  regenerating vectors on the AI side (`src/embedding.py`).
- Mirror the AI side: when this schema changes, check `hannoon-ai/src/db/` and `storage.py`; when
  the AI side adds a column, add the migration here. Keep the table in `../../AGENTS.md` updated.

### Testing Requirements
- Function/trigger changes need a matching pgTAP test in `../tests/`.

## Dependencies

### Internal
- Consumed by the client app (RPC/REST) and by `../../../hannoon-ai/src/db`.
- `../snippets/set_updated_at_trigger.sql` provides the shared `set_updated_at` trigger pattern.

### External
- Postgres 17, pgvector, pg_trgm, pg_net (Supabase-managed `extensions` schema).

<!-- MANUAL: -->
