# 22 — Agentic workflow efficiency (automations that cut real waste)

These automations came out of a measured production run (see the case study). Each one targets a
specific, **measured** loss — not a guess.

## The measurements that motivated them

| Signal | Value | Loss it represents |
|---|---|---|
| merged PRs / people / build window | 98 PRs · 5 people · ~15h | throughput baseline |
| PR cycle (open→merge) | p50 **5.6 min**, p90 37.6 min, max 72 min | queue tail |
| merge-agent `arm failed` vs `armed` | **77 vs 65** | >1 wasted retry per merge |
| organic conflicts needing resolution | 5 / 101 PRs | spec discipline worked |
| escalations | exercised on engineered test fixtures | validated the path, but not an organic metric |
| worktrees accumulated | **80** for one repo | dead capacity + noise |
| runs `cancelled` | **64 / 150** | serialized runner + no concurrency cancel |
| false CI failures | missing `node`, `gh`, `pnpm`; port 4173 in use | toolchain + shared-runner drift |

## 1. Task dispatcher — `bin/orca-dispatch`
Turns a brief into a worktree + agent + linked issue in one command, replacing the manual
"create worktree, paste brief" step that was the biggest human cost (98×).

```bash
orca-dispatch P1-08 --agent claude           # reads docs/tasks/P1/P1-08-*.md
orca-dispatch P1-08 --dry-run                # show the orca command without running it
```

It resolves the linked issue (`--issue`, else the `[ID]` title match), sets the owner from
`.orca-owner`, and passes the brief as the agent prompt.

## 2. Merge-agent guards — `merge-agent/orca-merge-agent`
- **Draft guard:** drafts are skipped and de-labeled `merge-ready` (GitHub will not merge a draft;
  retrying one every 2 min produced the `arm failed` loop).
- **Backoff:** a failing PR is retried every `RETRY_EVERY` passes and at most `MAX_ATTEMPTS`
  times, then parked — so one broken PR can't monopolise the loop.
- **Real error logging:** captures the actual `gh` message, not just "arm failed".
- **Queue observability:** each pass logs `pass #N: K merge-ready PR(s) pending`.

## 3. Runner bootstrap + health
- `systemd/orca-runner-bootstrap.sh <owner/repo>` — provisions node 22, pnpm, gh, Playwright libs
  and registers the runner. One command makes a box a fully-provisioned runner.
- `systemd/orca-runner-health.{service,timer}` — every 5 min: restarts an offline runner, frees
  stale CI ports, self-heals pnpm. This is the fix for the whole "false failure" family.

## 4. CI hardening — `github/ci.yml`
- `concurrency: cancel-in-progress` — kills the cancelled-run pile-up.
- **Runner preflight step** — asserts `node`/`pnpm` exist and frees ports 4173/4174, failing fast
  with a clear message instead of a confusing mid-job error.

## 5. Worktree reaper — `bin/orca-reap`
Removes worktrees whose PR merged (and abandoned clean ones older than `--age-days`), conservatively
never deleting unmerged commits. Use a timer for hands-off hygiene:

```bash
orca-reap --repo ~/megathon-gs-vanguard --dry-run
orca-reap --repo ~/megathon-gs-vanguard --age-days 7
```

## 6. Tracking loop — `github/` + `bin/task`
The issue/board side (doc 19) is now one command to set up and one CLI to drive:

```bash
github/setup-issues.sh <owner/repo> --phases P0 P1 P2 --gh <Owner>-gh
task status                 # ready / in-progress / review / blocked
task next --phase P1 --n 3
task start P1-08 --agent claude
task done  P1-08
```

See `github/README.md` for the full state model and Actions (`task-sync.yml`, `task-reconcile.yml`).

## Suggested timers (systemd, per user)

```ini
# ~/.config/systemd/user/orca-reap.timer
[Timer]
OnCalendar=hourly
Unit=orca-reap.service
```
Install the runner health timer from `systemd/orca-runner-health@.timer`.

## Order of adoption (highest ROI first)
1. Runner bootstrap + health (removes the largest false-failure class).
2. Merge-agent draft guard + backoff (removes ~half the merge-loop traffic).
3. `github/setup-issues.sh` + `task` CLI (makes tracking hands-off).
4. CI concurrency + preflight.
5. `orca-reap` on a timer.