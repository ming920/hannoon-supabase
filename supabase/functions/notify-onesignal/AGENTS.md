<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-07-01 | Updated: 2026-07-01 -->

# notify-onesignal

## Purpose
Deno edge function invoked by the `notify_onesignal_on_notification_insert` DB trigger
(`net.http_post`) when a row is inserted into `notifications`. It looks up the topic title and
sends a OneSignal push to the subscribing user.

## Key Files
| File | Description |
|------|-------------|
| `index.ts` | `Deno.serve` handler: verifies `WEBHOOK_SECRET` bearer → fetches `topics.title` via service-role client → sends OneSignal v2 push (`include_aliases.external_id = [user_id]`, `target_channel: "push"`) → click URL `…/event-detail/{event_id}` |

## For AI Agents

### Working In This Directory
- **Public endpoint, self-authenticated.** If `WEBHOOK_SECRET` is set, the handler requires
  `Authorization: Bearer <secret>`; if unset, verification is skipped (local-dev convenience).
  This is why it deploys with `--no-verify-jwt` and `config.toml` sets `verify_jwt = false`.
- Message text is identical for `ko` and `en`: `"{topic_title}에 새로운 사건이 등록되었습니다."`.
- The trigger reads `edge_function_url` and `webhook_secret` from `private.app_config`
  (UPSERTed in the deploy workflow). Keep the URL/secret wiring in sync with
  `migrations/20260526000000_notify_onesignal_webhook.sql` and `..._onesignal_config_table.sql`.

### Common Patterns
- Returns `401` (bad secret), `500` (topic fetch failed), `502` (OneSignal failed), `200` (ok).

## Dependencies

### External
- `jsr:@supabase/supabase-js@2`, `npm:@onesignal/node-onesignal@5.7.0`.
- Env: `WEBHOOK_SECRET`, `ONESIGNAL_APP_ID`, `ONESIGNAL_REST_API_KEY` (GitHub Secrets →
  `supabase secrets set`); `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` (auto-injected).

<!-- MANUAL: -->
