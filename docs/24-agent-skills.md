# 24 — Agent skills (what the agents can do, and how to add more)

Skills are small, tool-agnostic instruction sets the coding agents load automatically. This kit
ships and versions its own skills, and documents the third-party ones it relies on.

## Installed globally, in three places
| Location | Scope | Read by |
|---|---|---|
| `~/.agents/skills/` | shared, all agents | Orca-launched sessions, generic CLI clients |
| `~/.config/opencode/skills/` | OpenCode v2 | `opencode2` (symlink into the shared dir) |
| `~/.claude/skills/` | Claude Code | `claude` |

Install the kit's skills with one command (idempotent):

```bash
skills/install.sh            # copies all kit skills to ~/.agents/skills + symlinks OpenCode/Claude
skills/install.sh task-workflow orca-kit
```

## Skills in this kit
| Skill | Use it when… |
|---|---|
| **`merge-agent`** | landing `merge-ready` PRs, classifying and resolving conflicts, escalating the hard ones |
| **`task-workflow`** | picking up / starting / closing a task, updating labels or the board, creating issues |
| **`orca-kit`** | orienting in the workspace: worktrees, per-person routing, CI runners, config |

Each is a `SKILL.md` with a `name`, a trigger-focused `description`, a "when to use" section, the
steps/policy, and guardrails. `skills/_template/SKILL.md` is the starting point for new ones.

## Third-party skills the workspace relies on
| Skill(s) | Source | Install |
|---|---|---|
| `orca-cli`, `orchestration` | Orca bundle | `orca skills install` |
| `ponytail`, `ponytail-review`, `ponytail-audit`, `ponytail-debt`, `ponytail-gain`, `ponytail-help` | Ponytail ruleset | `npx skills add DietrichGebert/ponytail --skill '*' --global --agent '*' -y` |
| `find-skills` | community skills CLI | `npx skills add … --global` |

Ponytail also installs as a **plugin** in each agent (Claude/Codex/OpenCode/Cursor/`agy`) — see
`docs/20-ponytail.md` for the full matrix. It is the ruleset that keeps agents writing the least
code that works.

## Why skills (vs. just docs)
- Agents **load them automatically** when the trigger matches — no copy-paste, no drift.
- They are **versioned with the kit**, so a new repo/person gets the same behaviour.
- They encode **policy** (don't merge your own PR; honour owned paths; escalate semantic
  conflicts) at the point the agent acts, not in a document nobody re-reads.

## Anatomy
```markdown
---
name: <name>
description: >-
  WHEN to use (trigger phrases). Add "Do not use for <other> (use `<other-skill>`)."
---

# Title
## When to use
## Steps / policy
## Guardrails
```
Keep `description` about **when**; keep the body about **what**. Skills run with the agent's full
permissions — review before installing (as the skills CLI also warns).

## Adding a skill for your project
1. `cp -r skills/_template skills/<name>` and write `SKILL.md`.
2. `skills/install.sh <name>`; test it in one agent session.
3. Add a row to the table in `skills/README.md` and commit it with the kit so everyone gets it.

## Verify
```bash
ls ~/.agents/skills ~/.config/opencode/skills ~/.claude/skills
grep -l 'name:' ~/.agents/skills/*/SKILL.md
```