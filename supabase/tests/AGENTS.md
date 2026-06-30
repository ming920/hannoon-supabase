<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-07-01 | Updated: 2026-07-01 -->

# tests

## Purpose
pgTAP test suite. CI (`.github/workflows/ci.yaml`) runs `supabase db reset` then `supabase test db`,
which executes every `*.sql` here against a fresh local database — so tests cover triggers,
counters, RLS, and RPC behavior, not just schema existence.

## Key Files
| File | Description |
|------|-------------|
| `profiles_table.sql` | `profiles` schema/RLS + `handle_new_user` / `get_profile` |
| `subscriptions_test.sql` | `subscribe_topic` / `unsubscribe_topic` + RLS |
| `list_query_functions_test.sql` | `get_topics` / `get_events` pagination & subscription flags |
| `get_topic_and_events_test.sql` | `get_topic` / `get_events_by_topic` cursor pagination |
| `get_articles_by_event_test.sql` | `get_articles_by_event` page pagination + bias filter |
| `get_abusing_articles_by_event_test.sql` | `get_abusing_articles_by_event` pagination |
| `update_event_counts_on_article_insert_test.sql` | count trigger on `event_articles` insert |
| `decrement_bias_count_on_abusing_insert_test.sql` | bias-count decrement on `abusing_articles` insert |
| `increment... (fix_increment_abusing_count migration)` | covered alongside abusing tests |
| `notifications_test.sql` | notifications trigger + RPC read/mark/delete |
| `viewed_events_test.sql` | `get_event` upsert + `get_viewed_events` window |
| `delete_user_test.sql` | `delete_user()` cascade (profiles → subscriptions/notifications) |

## For AI Agents

### Working In This Directory
- Use pgTAP assertions (`plan()`, `is()`, `results_eq()`, `throws_ok()`, `finish()`).
- When you change a function, trigger, or RLS policy in `../migrations/`, add or update the
  matching test here — CI only runs these, it does not assert schema diffs.
- Tests assume a clean `db reset` state; seed any rows the test needs within the test.

## Dependencies

### Internal
- The migration chain in `../migrations/` (functions/triggers under test).

### External
- pgTAP (bundled with the Supabase test runner).

<!-- MANUAL: -->
