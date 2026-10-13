# AGENTS.md — install and operate the Orca Hackathon Kit

<!-- This file is written for a coding AGENT, not a human. Humans: see README.md and GUIDE.md. -->

**You are an agent (Claude Code, Codex, OpenCode, Cursor, Gemini, …). This file tells you how to
install, configure, and operate the Orca Hackathon Kit in a workspace. Follow it top to bottom, and
stop to ask the user only where marked ASK.**

---

## 0. What this kit is (10-second model)
A self-hosted, multi-agent coding workspace. One host runs Orca plus a fleet of coding agents. Each
task gets its **own git worktree**; work lands through **PRs**; a background **merge agent** serializes
merges, resolves safe conflicts (crediting combined authors), and escalates hard conflicts to the
author agents. A GitHub issue/board tracks tasks. Read `docs/00-index.md` only if you need depth.

## 1. First: detect state (always do this before anything else)
Run these and branch on the result:

```bash
pwd; git rev-parse --show-toplevel 2>/dev/null || echo "NOT_A_REPO"
ls orca-kit.env.example 2>/dev/null && echo "KIT_PRESENT"
command -v orca >/dev/null && echo "ORCA_OK" || echo "ORCA_MISSING"
command -v gh   >/dev/null && echo "GH_OK"   || echo "GH_MISSING"
```

- If `KIT_PRESENT` is **not** printed, you are in some other repo → jump to **§7 Install the kit**.
- If `ORCA_MISSING` → the host has no Orca runtime; **ASK** the user whether to provision one
  (see `GUIDE.md` → provisioning) before continuing.
- Otherwise continue to **§2**.

## 2. Configure (one file, no hardcoded paths)
Everything machine-specific lives in a single env file. **Never** hardcode paths — every kit script
sources `lib/orca-kit.sh`, which loads this file and fills gaps with computed defaults.

```bash
cp orca-kit.env.example ~/.orca-kit.env
# edit ~/.orca-kit.env — the values that matter:
#   KIT_HOME   ~              sibling trees (orca-docs, orca-merge, orca-keys, …)
#   KIT_OWNER  <you>          default owner for `.orca-owner` fallbacks / routing
#   MODEL      <provider/model>
#   GH         gh | <Name>-gh
#   REPO_SLUG  <owner/repo>   else discovered from `git remote origin`
```

Sanity check the resolution (must print resolved paths, not blanks):
```bash
. ./lib/orca-kit.sh && echo "home=$KIT_HOME merge=$MERGE_DIR model=$MODEL gh=$GH"
```

## 3. Install into a repository
Choose one:

```bash
# A. brand-new repo (clone + configure + CI)
./setup-new-repo.sh <owner/repo> [base_branch] [local_dir]

# B. existing local repo (no clone; GitHub optional)
./setup-existing-repo.sh <local_dir> [base_branch]
```
This copies `AGENTS.md` + templates + CI into the repo, writes the per-repo config, registers the
repo in Orca, and (if a GitHub remote exists) creates labels and the merge-agent timer.

## 4. The task pipeline (idea → plan → tasks → issues → board)
Run each stage, **show the user the output, and get agreement before the next stage** (the artefacts
are drafts until a human accepts them).

```bash
orca-plan init "<Project>"
orca-plan product docs/idea.md      # idea    → docs/product-plan.md            [ASK to confirm]
orca-plan plan                      # product → docs/technical-implementation-plan.md
orca-plan tasks --phases P0 P1 P2   # tech    → index table + one brief per task
orca-plan verify                    # validate graph; flags shared ownership

github/deps-from-index.py docs/tasks/README.md -o docs/tasks/deps.json
github/setup-issues.sh <owner/repo> --deps docs/tasks/deps.json --phases P0 P1 P2 --gh <Owner>-gh
```
Then drive it day to day:
```bash
task status / task next --phase P0 --n 5 / task start P0-04 --agent claude / task done P0-04
orca-dispatch P0-04 --agent claude     # brief → worktree + agent + linked issue
```

## 5. Rules you must follow while working (non-negotiable)
- **One task = one worktree = one agent = one PR.** Work only in your worktree.
- **Obey the brief.** Do only what `docs/tasks/…/<ID>*.md` names. No opportunistic refactors.
- **Respect owned paths.** Only edit the paths the brief/index lists. Shared registries have one
  writer per wave.
- **Freeze interfaces.** After the contracts task lands, changes to it are their own PR.
- **Do not merge your own PR.** Implement, get CI green, label it `merge-ready`, stop.
- **Never force-push** a shared branch. **Never commit secrets.**
- **`Co-authored-by:`** when you integrate someone else's work.
- **ASK** (don't guess) when the spec is silent/conflicting, a new dependency is needed, a public
  interface would change, or a frozen/do-not-touch path is involved.
- Definition of Done before `merge-ready`: acceptance passes · tests added · docs/ADR updated ·
  CI green · scope matches brief · no frozen paths touched.

## 6. Per-person routing (so keys/GitHub come out right)
- The **owner** of a worktree is `<worktree>/.orca-owner`, else `$ORCA_PERSON`, else `KIT_OWNER`.
- Launch agents through `orca-route <agent>` (or `orca-route-claude`, `orca-route-codex`, …) so the
  owner's env (`$KEYS_DIR/<owner>.env`: API keys, `GH_CONFIG_DIR`, git identity) is used.
- To act as a person: `echo <Name> > .orca-owner`, or `export ORCA_PERSON=<Name>`.
- Add a person: `orca-keys-add <Name>` then `orca-gh-add <Name> [token]`.

## 7. Install the kit itself (when §1 said it's absent)
```bash
git clone https://github.com/JAGUARAVI/orca-kit.git ~/orca-kit
cd ~/orca-kit && cp orca-kit.env.example ~/.orca-kit.env
# then continue at §2
```
Add `~/orca-kit/bin` to PATH so the CLIs (`orca-plan`, `orca-dispatch`, `task`, `orca-reap`) resolve:
```bash
export PATH="$HOME/orca-kit/bin:$PATH"     # or add to your shell profile
```

## 8. Optional add-ons (do only if the user asks)
- **CI on this host (unbilled runners):** `systemd/orca-runner-bootstrap.sh <owner/repo>`.
- **Agent skills:** `skills/install.sh` (installs `merge-agent`, `task-workflow`, `orca-kit`).
- **Least-code ruleset (Ponytail):** see `docs/20-ponytail.md` (installs per agent).
- **Pool accounts so runs don't stall on quota:** see `docs/25-teamclaude-account-pooling.md`.
- **Add more agents (Gemini/Aider/goose…):** see `docs/27-adding-agents.md`.

## 9. Where to look when stuck
| Need | File |
|---|---|
| Doc index | `docs/00-index.md` |
| Human guide | `GUIDE.md` |
| Task → issues → board | `docs/19-task-breakdown-and-issues.md` |
| Whole plan pipeline | `docs/23-idea-to-task-dag.md` |
| Merge agent behaviour | `docs/06-merge-agent.md` |
| Troubleshooting | `docs/09-troubleshooting.md` |
| The worked example | `docs/26-case-study.md` |

## 10. Hard stop conditions (stop and report to the user)
- A stage would overwrite existing plan artefacts without review.
- You are asked to act outside this kit's scope (e.g. share one person's account between people).
- A secret, token, or access link would be printed, logged, or committed.
- CI/branch rules would need to be weakened to land the work.