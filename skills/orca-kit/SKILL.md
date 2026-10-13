---
name: orca-kit
description: >-
  Orient an agent inside an Orca multi-agent workspace: worktrees, per-person routing, the merge
  agent, CI runners, and the config file. Use when asked "how does this workspace work", "which
  worktree am I in", "who owns this", "how do I route to a person", "where are the keys/CI", or
  when the agent needs to know how work lands. Do not use for a specific task's steps (use
  `task-workflow`) or for merging (use `merge-agent`).
---

# Orca kit orientation

## Topology
- One host runs Orca + a fleet of agents (Claude Code, Codex, OpenCode v2, Cursor, Antigravity).
- Each task gets its own **git worktree** (`orca worktree create`); work lands via PRs.
- A background **merge agent** serializes merges, resolves safe conflicts, escalates hard ones.
- **Self-hosted CI runners** execute Actions on the VMs (no GitHub minutes).

## Where things live (all from one config)
Everything is resolved by `lib/orca-kit.sh` from `~/.orca-kit.env` (or defaults):
`KIT_HOME`, `MERGE_DIR`, `KEYS_DIR`, `PEOPLE_DIR`, `HACKATHON_DIR`, `MODEL`, `GH`, `RUNNER_*`.
Never hardcode paths — source the lib.

```bash
. /path/to/orca-kit/lib/orca-kit.sh   # then use $MERGE_DIR, $KEYS_DIR, $AGENT_BIN, ...
```

## Per-person routing
- The **worktree owner** is `<worktree>/.orca-owner`, else `$ORCA_PERSON`/`$ORCA_OWNER`, else the
  configured default owner.
- Owner → that person's env (`$KEYS_DIR/<Owner>.env`: keys, `GH_CONFIG_DIR`, git identity).
- Launch agents through `orca-route <agent>` (e.g. `orca-route-claude`) so the right keys/GitHub
  identity are used automatically.

## Worktrees
```bash
orca worktree ps                 # orchestration summary
orca worktree list               # all worktrees
orca-reap --repo <dir> --dry-run # remove merged/abandoned worktrees
```

## CI runners
```bash
systemd/orca-runner-bootstrap.sh <owner/repo>   # provision this box as a runner
systemd/orca-runner-health.sh                   # restart/free ports/self-heal (via timer)
```
A shared runner is never clean: free CI ports and assert tools before trusting a failure.

## Guardrails for agents
- Stay inside the worktree; don't switch branches of a shared checkout.
- Don't touch `main` directly; land through a PR labeled `merge-ready`.
- Don't paste secrets into logs; keys live in `$KEYS_DIR/<Owner>.env` (600).
- If a conflict is semantic (same logic/contract), don't guess — escalate.