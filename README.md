# Orca Hackathon Kit

A reusable, self-hosted **multi-agent coding workspace** with an **automated merge agent** and a
**spec-driven workflow** that keeps parallel agents from drifting.

One host runs Orca and a fleet of coding agents (Claude Code, Codex, OpenCode v2, Cursor). Each task
gets its own git worktree; work lands through PRs; a background **merge agent** serializes merges,
resolves safe conflicts (crediting combined authors), and escalates hard questions to the agents that
wrote the code. A shared GitHub Project board tracks features and decisions.

## Configuration (no hardcoded paths)
Everything machine-specific lives in **one file** — copy `orca-kit.env.example` to
`~/.orca-kit.env` (or `/etc/orca-kit.env`) and edit:

```bash
KIT_HOME=~           # sibling trees (orca-docs, orca-merge, orca-keys, ...)
KIT_OWNER=me         # default owner for `.orca-owner` fallbacks / routing
MODEL=<provider/model>
GH=gh                # or a <Name>-gh wrapper
REPO_SLUG=<owner/repo>   # else discovered from `git remote origin`
```

Every script sources `lib/orca-kit.sh`, which loads that file and fills any gap with computed
defaults — so the kit runs with no config on a single-user machine and scales to a team.

**Placeholders in this kit:** `<owner>`, `<owner/repo>`, `<Name>`, `<PHASE>` (P0/P1/…), `<ID>`,
`<repo-dir>`. Worked examples that use a specific repo/name are labelled *example*.


## Quickstart (one command for a new repo)
```bash
./setup-new-repo.sh <owner/repo> [base_branch] [local_dir]
```

## Set up an existing local repo (no clone)
```bash
./setup-existing-repo.sh <local_dir> [base_branch]
```
Copies AGENTS.md + templates + docs + CI, writes the per-repo config, registers the repo in Orca,
and — if a GitHub remote exists — creates labels, protection and the merge-agent timer.

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
| 19 | **Plan → tasks → issues → board** |
| 20 | **Ponytail** ruleset in every agent |
| 21 | **Self-hosted CI runner** (unbilled GitHub Actions) |
| 22 | **Efficiency automations** (dispatcher, merge guards, runner health, reaper) |
| 23 | **Idea → product plan → technical plan → parallel task DAG** (the whole pipeline) |
| 24 | **Agent skills** (what the agents can do, and how to add more) |
| 25 | **TeamClaude account pooling** (pool Claude/Codex accounts so agents don't stall on quota) |
| 26 | **Case study** (the megathon run: 98 PRs, 5 people, one host) |

## Templates (`templates/`) — copy into your repo
`PRODUCT-PLAN.md` · `SPEC.md` · `ADR.md` · `AGENTS.md` · `TASKS-README.md` · `TASK-BRIEF.md`

## Team-facing (`welcome/`)
`WELCOME.md` · `PLAYBOOK.md` (day-to-day) · `SUMMARY.md` · `INVITE-TEMPLATE.md`

## Idea → product plan → technical plan → task DAG → issues → board (one toolchain)
```bash
orca-plan init "My Project"                 # scaffold PRODUCT-PLAN/SPEC/AGENTS/docs/tasks templates
orca-plan all docs/idea.md                  # idea -> product plan -> tech plan -> task DAG (review each)
# or stage by stage:
orca-plan product docs/idea.md              # idea   -> docs/product-plan.md
orca-plan plan                              # product -> docs/technical-implementation-plan.md
orca-plan tasks --phases P0 P1 P2           # tech   -> index table + one brief per task
orca-plan verify                            # validate graph; flag shared ownership

github/deps-from-index.py docs/tasks/README.md -o docs/tasks/deps.json
github/setup-issues.sh <owner/repo> --deps docs/tasks/deps.json --phases P0 P1 P2 --gh <Owner>-gh
```
Then drive it day to day:
```bash
task status / task next --phase P1 / task start P1-08 --agent claude / task done P1-08
orca-dispatch P0-04 --agent claude          # brief -> worktree + agent + linked issue
```
See `docs/23-idea-to-task-dag.md` and `github/README.md`.

## Contents
- `setup-new-repo.sh` / `setup-existing-repo.sh` — bootstrap or retrofit a repository.
- `bin/` — `orca-plan`, `orca-dispatch`, `task`, `orca-reap`.
- `github/` — issue/label/board toolchain (`setup-issues.sh`, `create-task-issues.py`,
  `deps-from-index.py`, `reconcile-task-issues.py`, `task-sync.yml`, `board-sync.sh`,
  `issue-templates/`, `ci.yml`).
- `merge-agent/` — `orca-merge-agent` (draft guard + backoff), `orca-merge-resolve.sh`, `orca-author-respond`.
- `person/` — `orca-keys-add`, `orca-gh-add`, `orca-route`, `orca-route-*`.
- `systemd/` — merge-agent units, `orca-runner-bootstrap.sh`, `orca-runner-health@.*`.
- `skills/` — agent skills (`merge-agent`, `task-workflow`, `orca-kit`) + `install.sh`.

## License
MIT — see [LICENSE](LICENSE).
