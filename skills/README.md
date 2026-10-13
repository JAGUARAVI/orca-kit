# Agent skills shipped with the kit

Skills are the agent-facing half of the kit: small, tool-agnostic instruction sets the coding
agents load automatically. They are installed **globally** (so every person and every agent gets
them) and are also **committed here** so they are versioned with the kit.

## What is installed, and where

| Location | Scope | Who reads it |
|---|---|---|
| `~/.agents/skills/` | shared, all agents | Orca-launched sessions, generic clients |
| `~/.config/opencode/skills/` | OpenCode v2 | `opencode2` (symlink into `~/.agents/skills`) |
| `~/.claude/skills/` | Claude Code | `claude` |

Install (copies the kit's skills to the shared dir and symlinks OpenCode):

```bash
skills/install.sh                 # all skills in this directory, for the current user
skills/install.sh migrate         # only the kit-authored ones
```

## Skills in this kit

| Skill | Purpose |
|---|---|
| `merge-agent` | Land `merge-ready` PRs, classify and resolve conflicts, escalate the hard ones. |
| `task-workflow` | Operate the task system: `task status/next/start/done`, labels, board, briefs. |
| `orca-kit` | Orient an agent in an Orca multi-agent workspace (worktrees, routing, ownership). |

## Supplied by third parties (installed separately)

| Skill(s) | Source | Install |
|---|---|---|
| `orca-cli`, `orchestration` | Orca | `orca skills install` |
| `ponytail*` (6 skills) | [Ponytail](https://ponytail.dev) ruleset | `npx skills add DietrichGebert/ponytail --skill '*' --global --agent '*' -y` |
| `find-skills` | community skills CLI | `npx skills add <repo> ...` |

See `docs/20-ponytail.md` for the Ponytail install matrix (Claude, Codex, OpenCode, Cursor, `agy`).

## Anatomy of a skill

```
skills/<name>/SKILL.md
---
name: <name>
description: >-
  When the agent should use this skill (trigger phrases). Keep it specific — this is what the
  agent matches on. Do not use for <other case>.
---

# <Title>
## When to use
## Steps / policy
## Guardrails
```

Keep `description` focused on **when to use**, and the body on **what to do**. Skills run with the
agent's full permissions, so review before installing (the skills CLI warns about this too).

## Authoring a new skill

1. `cp -r skills/_template skills/<name>` and edit `SKILL.md`.
2. Test it in one agent session before committing.
3. Add a row to the table above.

`skills/_template/SKILL.md` is the starting point.