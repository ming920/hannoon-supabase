<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-07-01 | Updated: 2026-07-01 -->

# functions

## Purpose
Supabase Edge Functions (Deno). Deployed via `supabase functions deploy` in the deploy workflow.

## Subdirectories
| Directory | Purpose |
|-----------|---------|
| `notify-onesignal/` | DB-trigger webhook that sends OneSignal push on new notifications (see `notify-onesignal/AGENTS.md`) |

## For AI Agents

### Working In This Directory
- Each function is its own folder with an `index.ts` entry (`Deno.serve`).
- Functions deploy with `--no-verify-jwt` only when the function self-authenticates (see
  `notify-onesignal`); the corresponding `config.toml` `[functions.<name>] verify_jwt = false`
  must match.

<!-- MANUAL: -->
