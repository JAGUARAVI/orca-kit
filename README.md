# Orca Hackathon Kit

A reusable, self-hosted **multi-agent coding workspace** with an **automated merge agent** and a
**spec-driven workflow** that keeps parallel agents from drifting.

One host runs Orca and a fleet of coding agents (Claude Code, Codex, OpenCode v2, Cursor). Each task
gets its own git worktree; work lands through PRs; a background **merge agent** serializes merges,
resolves safe conflicts (crediting combined authors), and escalates hard questions to the agents that
wrote the code. A shared GitHub Project board tracks features and decisions.

## Quickstart (one command for a new repo)
```bash
./setup-new-repo.sh <owner/repo> [base_branch] [local_dir]
```

## Full guide
**[GUIDE.md](GUIDE.md)** — provisioning, per-person profiles, daily workflow, the merge agent,
multi-repo operation, troubleshooting.

## Documentation (`docs/`)
| # | Doc |
|---|---|
| 01–12 | architecture, access, agents, model config, per-person keys, merge agent, security, runbook, troubleshooting, board, porting, per-person GitHub auth |
| 13 | **Orca features & maximum-productivity patterns** |
| 14 | **Specs, architecture & guardrails** (stop agents wandering) |
| 15 | **Dividing work & delegating to agents** |
| 16 | **Agent playbook** (rules for agents) |
| 17 | **Conventions, glossary & FAQ** |

## Templates (`templates/`) — copy into your repo
`SPEC.md` · `ADR.md` · `AGENTS.md` · `TASK-BRIEF.md`

## Team-facing (`welcome/`)
`WELCOME.md` · `PLAYBOOK.md` (day-to-day) · `SUMMARY.md` · `INVITE-TEMPLATE.md`

## Contents
- `setup-new-repo.sh` — bootstrap a repository.
- `github/` — `ci.yml`, `configure-repo.sh` (branch protection), `setup-board.sh`.
- `merge-agent/` — `orca-merge-agent`, `orca-merge-resolve.sh`, `orca-author-respond`.
- `person/` — `orca-keys-add`, `orca-gh-add`, `orca-route`, `orca-route-*`.
- `systemd/` — service + timer units.
- `skills/merge-agent/` — the agent skill.

## License
MIT — see [LICENSE](LICENSE).
