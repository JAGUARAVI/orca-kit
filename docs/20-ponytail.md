# 20 — Ponytail (agent ruleset: write the least code that works)

[Ponytail](https://ponytail.dev) is a ruleset/plugin that makes coding agents write the minimum
that works: stop at the first rung that holds (skip it → reuse it → stdlib → platform → installed
dep → one line → minimum + one test). Reported: **-53% code, -45% output tokens, -26% cost,
-41% time**, with validation/security/accessibility never simplified away, plus
`/ponytail-review`, `/ponytail-audit`, `/ponytail-debt`, `/ponytail-gain`, `/ponytail-help`.
Levels: `/ponytail lite|full|ultra|off` (default **full**).

## Installed on the host (all agents)
| Agent | Method | Result |
|---|---|---|
| Claude Code | `/plugin marketplace add DietrichGebert/ponytail` + `/plugin install ponytail@ponytail` | `ponytail@ponytail` 5.1.0, enabled, scope user |
| Codex | `codex plugin marketplace add …` + `codex plugin add ponytail@ponytail` | installed, enabled 5.1.0 (open `/hooks` to trust the two hooks) |
| OpenCode 2 | `opencode2 plugin add @dietrichgebert/ponytail` | registered 5.1.0 (adds `/ponytail` commands + levels) |
| Cursor | `git clone … && node scripts/cursor-hooks.js install` | 2 hooks merged into `~/.cursor/hooks.json` |
| Antigravity (`agy`) | `agy plugin install https://github.com/DietrichGebert/ponytail` | extension at `~/.gemini/config/plugins/ponytail` (commands converted to skills) |

Plus, for every agent (belt-and-braces) and for **Orca-launched** sessions:
- `AGENTS.md` → `~/.codex/AGENTS.md` (Codex reads `AGENTS.md`; OpenCode auto-loads it per repo).
- Six skills copied to `~/.agents/skills/` (`npx skills add DietrichGebert/ponytail --skill '*' --global --agent '*' -y`)
  and symlinked into `~/.config/opencode/skills/` and `~/.claude/skills/`.
- Default level for all new sessions: `~/.config/ponytail/config.json` = `{"defaultMode":"full"}`
  and `PONYTAIL_DEFAULT_MODE=full` in `~/.profile`.
- Checkout kept at `~/ponytail` (Cursor hooks run `node` from it — do not move it without re-running).

## Per-person note
The plugin/skills install is **host-wide** (one host, shared runtime), so all five people get
Ponytail in every agent. `PONYTAIL_DEFAULT_MODE` is per-shell if someone wants a different level:
`export PONYTAIL_DEFAULT_MODE=lite|full|ultra|off`.

## Verify
```bash
claude plugin list | grep -i ponytail
codex plugin list  | grep -i '^ponytail'
opencode2 plugin list | grep -i ponytail
grep -c ponytail ~/.cursor/hooks.json
ls ~/.agents/skills | grep ponytail
# functional (OpenCode):
cd /srv/orca-demo && Avi-opencode2 run --standalone --model fireworks-azure/Avi-DeepSeek-V4.1-Flash \
  "Add a date picker component. Reply with the approach in one line."
# -> "Add <input type=\"date\"> … no dependency."
```

## Notes
- Requires **node** on PATH (v22 present) for the Claude/Codex/Cursor hooks; skills work regardless.
- Codex: run `codex`, open `/hooks`, review and trust the two lifecycle hooks, start a new thread.
- Codex/Claude OAuth sessions must be live to use those agents (unrelated to Ponytail).
- Uninstall: `opencode2 plugin remove @dietrichgebert/ponytail`, `claude plugin remove ponytail`,
  `codex plugin remove ponytail`, `node ~/ponytail/scripts/cursor-hooks.js uninstall`, and remove
  the `agy` extension.
