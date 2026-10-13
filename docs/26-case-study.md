# 26 — Case study: shipping a 59-task product with 5 people and a fleet of agents

This is the run the kit was extracted from: **Paisa Street**, a financial-literacy game built for the
Megathon, delivered in a single weekend. It is included because the numbers are real, the failures
are real, and every lesson maps to a file in this kit.

## The shape of it
| | |
|---|---|
| People | **5** (`JAGUARAVI` 46 PRs · `Dan1718` 17 · `parth-tehlan` 14 · `EkanshWadhwa39` 12 · `shaurya-vsc` 9) |
| Wall-clock | **~36 hours** (repo created `2026-10-09 17:17Z` → last push `2026-10-11 05:15Z`) |
| Merged PRs | **98** (plus 4 closed unmerged) |
| Commits on `main` | **114** — of which **67** carry `Co-authored-by` credit |
| Code | **+54,668 / −1,667** lines across **1,372** files (TypeScript 921 KB, CSS 56 KB) |
| Tasks | **59 briefs** (P0: 23 · P1: 14 · P2: 22) + a hand-written gate checklist → **74 issues**, 71 closed |
| Host | one VM running Orca + Claude Code / Codex / OpenCode v2 / Cursor |
| Merge agent | **101 PRs** handled: 65 armed · 8 conflicts resolved · 3 escalated to authors |

That is roughly **2.7 merged PRs per hour per person**, on a shared `main`, with two unrelated
features landing in the same files repeatedly.

## What actually worked

**1. Spec-first, dependency-ordered task graph (docs 19, 23).**
The product plan and technical plan were decomposed into 59 briefs, each owning **disjoint paths**,
with interfaces frozen first. The proof it worked: only **8 of 101 PRs** hit a merge conflict, and
only **3** needed a human escalation. Conflicts weren't prevented by luck — they were prevented by
sequencing the shared interfaces (`contracts`, registries, locale files) behind a single writer.

**2. The merge agent (docs 06, 22).**
It serialized 98 merges, auto-resolved the safe conflicts, and — the part that matters at speed —
**attributed combined work**: 67 commits credit co-authors, so a PR that landed B's work on top of
A's changes names both. The 3 escalations were genuine semantic conflicts (`RATE = 2` vs `RATE = 5`);
it asked the authors instead of guessing. p50 PR cycle was **5.6 minutes**.

**3. Per-person isolation (docs 05, 12).**
Five people on one box, each with an isolated `HOME`/config dir and their own `gh` identity, so
`git push` and issue creation were correctly attributed (46/17/14/12/9 PRs line up with real logins).
No account sharing, no cross-contamination of Claude/Codex/OpenCode state.

**4. One task = one worktree = one agent = one PR (doc 15).**
80 worktrees were created from the task briefs. Agents never fought over a checkout; the brief was
the prompt, so an agent's scope was bounded before it started.

**5. The board + label state machine.**
74 issues with `ready`/`blocked`/`in-progress`/`review` labels and dependency links; dependents
flipped `blocked → ready` automatically when their prerequisite merged. Nobody hand-tracked the DAG.

## What went wrong (and what it cost)
Honest accounting — this is the most useful part of the case study.

**1. E2E was the weak link.** Of **61** E2E workflow runs, **1 succeeded**. The suite itself was
mis-written by an agent (Playwright `test.use()`/`test.describe()` called from a config-imported
file) and the shared runner hit **load ~80 on 8 vCPUs** when several E2E jobs ran at once, so tests
were slow and flaky. **Lesson:** the E2E suite needs a *reviewed* author and a runner with headroom;
CI wall-clock is a capacity problem, not just a code problem → **doc 21** (self-hosted runner) and
the runner-health automation in **doc 22**.

**2. The merge agent's retry loop.** It logged **77 `arm failed` against 65 successful arms** — it
kept trying to merge PRs GitHub wouldn't merge (drafts, timings) every 2 minutes. Pure waste, and
the log gave no reason. **Lesson → doc 22:** skip drafts, back off, log the real error.

**3. Manual dispatch.** All 98 PRs were launched by hand (`orca worktree create --prompt <brief>`).
Mechanical, and the biggest human cost in the whole run. **Lesson → doc 22:** `bin/orca-dispatch`.

**4. CI capacity + churn.** **64 cancelled runs** in 150 — pushes queued behind a single runner. The
fix is parallel runners + `cancel-in-progress` (doc 22). The billing wall (`the job was not started
because recent account payments have failed…`) is what pushed us to self-hosted runners (doc 21).

**5. Toolchain drift on the shared box.** Repeated *false* CI failures from a missing `node`, `gh`,
or `pnpm`, and a stale `vite preview` squatting port 4173. Each looked like a code failure.
**Lesson → doc 22:** preflight + runner health.

**6. A few PRs sat. p90 cycle was 37 min, max 72 min** — queued behind the merge train during merge
bursts (14–15 merges/hour). Later PRs wait on earlier ones; a faster resolver or more parallel CI
would compress the tail.

## The numbers, in one place
```
throughput         98 merged PRs · ~2.7 PRs/hour/person · 36h wall-clock
code               +54,668 / −1,667 lines · 1,372 files · TypeScript
commits            114 on main · 67 with Co-authored-by
tasks              59 briefs (P0 23 · P1 14 · P2 22) · 74 issues · 71 closed
merge agent        101 PRs · 65 armed · 8 conflicts resolved · 3 escalated
PR cycle (open→merge)  p50 5.6 min · p90 37.6 min · max 71.9 min
CI (last 150 runs) 42 success · 44 failure · 64 cancelled   (E2E: 1 success / 61 — the weak link)
```

## What we changed in the kit because of this run
Every failure above became a concrete artefact, not a note:
| Observed problem | Kit artefact |
|---|---|
| 98 hand-launched worktrees | `bin/orca-dispatch` (doc 22) |
| 77 `arm failed` retries, drafts looping | merge-agent draft guard + backoff + real error log (doc 22) |
| missing node/pnpm/gh, port 4173 collisions | `systemd/orca-runner-bootstrap.sh`, `orca-runner-health@.timer`, CI preflight (docs 21, 22) |
| 64 cancelled runs | CI `concurrency: cancel-in-progress` (doc 22) |
| 80 dead worktrees | `bin/orca-reap` (doc 22) |
| tracking done by hand | `github/setup-issues.sh`, `bin/task`, `task-sync.yml`, `board-sync.sh` (docs 19, 22) |
| E2E mis-written / underpowered runner | runner bootstrap with Playwright libs + preflight (docs 21, 22) |
| quota stalls on long runs | TeamClaude account pooling (doc 25) |

## Reproduce the numbers
```bash
R=IIIT-ECell/megathon26-megathon-gs
gh pr list -R $R --state merged --limit 300 --json additions,deletions,changedFiles,author \
  --jq '"merged \(length)  +\(map(.additions)|add) -\(map(.deletions)|add)  files \(map(.changedFiles)|add)"'
gh pr list -R $R --state merged --limit 300 --json author --jq 'map(.author.login)|group_by(.)|.[]|"\(.[0]) \(length)"'
gh api repos/$R/commits?sha=main\&per_page=100 --jq '[.[]|select(.commit.message|test("Co-authored-by"))]|length'
gh run list -R $R --limit 150 --json conclusion --jq 'group_by(.conclusion)|.[]|"\(.[0].conclusion) \(length)"'
# merge agent (host): grep -c armed ~/.orca-merge/log/merge-agent.log
```

## Read it as a playbook
The run proves three things the kit now encodes:
1. **Disjoint ownership + frozen interfaces** let many agents share one `main` (8/101 conflicts).
2. **A merge agent with authorship accounting** is what makes a parallel fleet safe to trust.
3. **The failure mode is infrastructure, not the model** — quota, runners, toolchains, ports. Budget
   for CI capacity and runner health the same way you budget for agents.

See also: doc 15 (dividing work), doc 19 (tasks→issues), doc 22 (the automations born here),
doc 25 (account pooling for quota).