# Orca Hackathon Kit

A reusable, self-hosted **multi-agent coding workspace** with an **automated merge agent**.

One host runs Orca and a fleet of coding agents (Claude Code, Codex, OpenCode v2, Cursor).
Each task gets its own git worktree; work lands through PRs; a background **merge agent**
serializes merges, resolves safe conflicts, and escalates important questions to the
agents that wrote the code. A shared GitHub Project board tracks features and decisions.

## Quickstart (one command for a new repo)
```bash
./setup-new-repo.sh <owner/repo> [base_branch] [local_dir]
```
It clones the repo, adds a required-checks CI workflow, protects the base branch
(strict checks + auto-merge), creates the merge labels, installs the merge agent,
and registers the repo in Orca.

## Full guide
See **[GUIDE.md](GUIDE.md)** for provisioning the host, per-person profiles, the daily
workflow, the merge agent internals, multi-repo operation, and troubleshooting.

## Contents
- `setup-new-repo.sh` — bootstrap a repository.
- `github/` — `ci.yml`, `configure-repo.sh` (branch protection), `setup-board.sh`.
- `merge-agent/` — `orca-merge-agent`, `orca-merge-resolve.sh`, `orca-author-respond`.
- `person/` — `orca-keys-add`, `orca-route`, `orca-route-*`.
- `systemd/` — service + timer units.
- `skills/merge-agent/` — the agent skill.
- `docs/` — detailed technical docs.
- `welcome/` — team-facing welcome + invite template.

## License
MIT — see [LICENSE](LICENSE).
