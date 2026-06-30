<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-07-01 | Updated: 2026-07-01 -->

# snippets

## Purpose
Reusable SQL fragments — patterns copied/referenced by migrations rather than applied on their own.

## Key Files
| File | Description |
|------|-------------|
| `set_updated_at_trigger.sql` | The shared `set_updated_at BEFORE UPDATE` trigger pattern (`EXECUTE FUNCTION public.update_updated_at()`), applied per table (articles, topics, events) in the migrations |

## For AI Agents

### Working In This Directory
- These files are **reference snippets**, not part of the migration chain — `supabase db reset`
  does not run them. To take effect, the SQL must appear in a real `../migrations/` file.

<!-- MANUAL: -->
