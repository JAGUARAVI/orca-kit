# 03 — Agents

Installed (host):
| Agent | Version | Wrapper |
|---|---|---|
| Claude Code | 2.1.296 | `Avi-claude` |
| Codex | 0.162.0 | `Avi-codex` |
| OpenCode v2 | 2.0.26 (`opencode`, `opencode2`) | `Avi-opencode2` |
| Cursor CLI | 2026.10.01 | `Avi-cursor` |

Wrappers are named `<Owner>-<agent>` and live in `$LOCAL_BIN` (default `~/.local/bin`); each
sources that person's env file. Below, `Avi` is just the configured default owner (`KIT_OWNER`).

Orca's own agent picker launches the raw CLIs; Orca-launched agents inherit the
service environment (Avi's keys via `EnvironmentFile`). To give each person a
distinct Orca agent entry, use Settings → Agents (host-owned) or run their
`<Name>-<agent>` wrapper in a terminal.

## Default agent + per-person routing
- Orca default TUI agent = `opencode2`.
- `agentCmdOverrides` routes each agent through `~/bin/orca-route-<agent>`, which sources
  the worktree owner's env (`<worktree>/.orca-owner`, else `$ORCA_PERSON`, else Avi)
  from `~/.orca-keys/<owner>.env`, then execs the real agent. So Orca-launched agents
  use the correct person's keys automatically.

## Per-person status
- Avi: `Avi-opencode2` (Fireworks/Foundry), `Avi-claude` (config dir empty — login pending).
- Parth: `Parth-claude` (logged in, isolated), other agents blank until keys added.


## Google Antigravity (`agy`)
Installed at `~/.local/bin/agy` (v1.3.3). Per-person isolation is via an isolated `HOME`
(`~/.orca-people/<Name>/antigravity`) — official Google method. Wrappers:
`<Name>-antigravity` (+ `<Name>-antigravity-login`). See `18-antigravity-agent.md`.


## Ponytail (all agents)
Every agent ships with the **Ponytail** ruleset (least-code-that-works; default level `full`).
See `20-ponytail.md`. Switch level with `/ponytail lite|full|ultra|off`.

## Adding more agents
Any TUI agent can run under Orca. See `27-adding-agents.md` for the full loop: a per-person
`<Name>-<agent>` wrapper, an `orca-route-<agent>` routing wrapper, the Orca `agentCmdOverrides`
entry, and the shared rules/skills that keep behaviour consistent. Known Orca ids include
`claude`, `codex`, `omp`, `pi`, `grok`, `gemini`; anything else launches via
`orca terminal create --command`.
