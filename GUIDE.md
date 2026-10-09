# Orca Hackathon Kit — Detailed Guide

A complete, reusable setup for **parallel multi-agent coding with automatic merges** on a
single self-hosted host. This guide covers the host, the workflow, the merge agent, and
how to apply it all to any repository.

## Contents
0. [What you get](#0-what-you-get)
1. [Architecture](#1-architecture)
2. [Prerequisites](#2-prerequisites)
3. [Provision the host](#3-provision-the-host)
4. [Bootstrap a repository](#4-bootstrap-a-repository)
5. [Per-person profiles](#5-per-person-profiles)
6. [Daily workflow](#6-daily-workflow)
7. [The merge agent](#7-the-merge-agent)
8. [The shared board](#8-the-shared-board)
9. [Running multiple repositories](#9-running-multiple-repositories)
10. [Operations](#10-operations)
11. [Troubleshooting](#11-troubleshooting)
12. [Reference](#12-reference)

---

## 0. What you get
- One host running an **Orca runtime** (worktrees, terminals, agent processes).
- A fleet of coding agents (**Claude Code, Codex, OpenCode v2, Cursor**) with **per-person**
  credentials and isolated logins.
- Git-**worktree-per-task** isolation so agents can work the same files in parallel.
- A **required-checks CI** gate and protected base branch.
- An **automated merge agent** that lands ready PRs, resolves safe conflicts, and escalates
  hard ones to the author agents.
- A shared **GitHub Project board** for features/decisions.

## 1. Architecture
```
        teammates (laptop / phone)  ── Tailscale (private) ──►  Orca client
                                                                   │
                                                        shared Orca runtime (host)
                                                        ├─ worktrees (1 per task)
                                                        ├─ agents: claude/codex/opencode2/cursor
                                                        ├─ merge agent (systemd timer)
                                                        └─ per-person profiles + routing
                                                                   │
        GitHub: <owner>/<repo>  ── PRs ── required "checks" ── auto-merge
```
- The **host** owns repos, worktrees, terminals, and agent processes; clients are pure UI.
- **Worktrees** isolate tasks; **PRs** are the integration point; the **merge agent** automates
  landing.

## 2. Prerequisites
- A Linux host you control (Ubuntu 22.04/24.04), `sudo`, ≥8 vCPU / ≥32 GB RAM (16/64 recommended),
  Docker, and a few hundred GB disk.
- **GitHub** account; `gh` authenticated with scopes `repo`, `workflow`, `project`.
- **Tailscale** account (private networking; nothing exposed publicly).
- Model access: e.g. an Anthropic/OpenAI subscription or API keys, and (optionally) an
  OpenAI-compatible endpoint (shown here with Fireworks on Microsoft Foundry).
- Orca installed on the host.

## 3. Provision the host
> Full commands live in `docs/`. Summary:

```bash
# base tools
sudo apt-get update && sudo apt-get install -y git curl build-essential python3-venv python3-pip \
  jq htop tmux ripgrep unzip xvfb libfuse2t64
# Node 22 (NodeSource), Docker, gh, Tailscale
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - && sudo apt-get install -y nodejs
curl -fsSL https://get.docker.com | sudo sh
# gh + tailscale per their docs
npm i -g @anthropic-ai/claude-code @openai/codex
curl -fsSL https://opencode.ai/v2/install | bash
curl -fsSL https://cursor.com/install | bash
# Orca (Linux .deb)
curl -fsSLO https://github.com/stablyai/orca/releases/latest/download/orca-ide_<ver>_amd64.deb
sudo apt-get install -y ./orca-ide_<ver>_amd64.deb
```
Then:
- Start the runtime: `xvfb-run -a orca-ide serve --port 6768 --pairing-address <tailscale-ip>`
  (run it under systemd — see `systemd/orca-serve.service`).
- Firewall the Orca port to `lo` + `tailscale0` only.
- Configure the model/provider (see `docs/04-opencode-foundry.md` for the OpenCode example).

## 4. Bootstrap a repository
```bash
./setup-new-repo.sh <owner/repo> [base_branch] [local_dir]
```
It:
1. clones the repo to `local_dir` (default `/srv/<repo-name>`);
2. writes `/home/ubuntu/.orca-hackathon/config` (`REPO`, `BASE_BRANCH`, `REPO_DIR`);
3. adds `.github/workflows/ci.yml` (the required `checks` job) — via PR if protected;
4. creates labels `merge-ready`, `merge-conflict`, `needs-author-input`;
5. enables auto-merge and configures the `main-protection` ruleset (strict `checks`);
6. installs the merge-agent scripts and registers the repo in Orca.

Change the required approvals in `github/configure-repo.sh` (default `0`; set `1` for review).

## 5. Per-person profiles
Each person gets an env file, wrappers, and an isolated Claude config dir:
```bash
orca-keys-add <Name>
echo 'CLAUDE_CONFIG_DIR=/home/ubuntu/.orca-people/<Name>/claude' >> ~/.orca-keys/<Name>.env
# first login:
<Name>-claude
```
**Routing:** an Orca-launched agent reads the worktree's `.orca-owner` (fallback `$ORCA_PERSON`,
else the default person), sources that person's env, and execs the real agent. So each person's
agents use their own credentials. Put your name in a worktree once:
```bash
echo <Name> > .orca-owner   # gitignored
```

**Per-person GitHub auth** (commit/push/PR as your own account):
```bash
orca-gh-add <Name> <PAT>   # isolated gh config dir + git identity
```
The global git credential helper (`gh auth git-credential`) reads `GH_CONFIG_DIR` at runtime, so
each person's `gh` **and** `git push` use their own token; commits are authored as them. See
`docs/12-per-person-github-auth.md`.

## 6. Daily workflow
```bash
orca-ide worktree create --name feat-x --agent opencode2 --prompt "implement X" --json
echo <Name> > .orca-owner
# work with <Name>-opencode2 / <Name>-claude / ...
git add -A && git commit -m "feat: X" && git push -u origin <branch>
gh pr create --fill --base <base_branch>
gh pr edit <n> --add-label merge-ready       # hand off to the merge agent
```
Move your card through the board's **Status** column; set **Owner** and **Worktree**.

## 7. The merge agent
Config-driven by `/home/ubuntu/.orca-hackathon/config`. Runs every 60s via systemd
(`orca-merge-agent.timer`).
**Flow:**
1. PR labeled `merge-ready` → update branch onto base → enable auto-merge.
2. On conflict → an LLM agent resolves **only if safe**:
   - disjoint edits → auto; append-only logs (`*.jsonl`) → union; generated → regenerate;
   - semantic overlap / frozen paths → **escalate**.
3. Escalation writes `~/.orca-merge/questions/<pr>.json`, labels `merge-conflict` +
   `needs-author-input`, and comments.
4. The author agent answers: `orca-author-respond <author-label> <pr>` → next pass applies it.
**Logs:** `~/.orca-merge/log/merge-agent.log`, `resolve-<pr>.log`.
**Manual run:** `/home/ubuntu/bin/orca-merge-agent`.

## 8. The shared board
```bash
./github/setup-board.sh <owner> "Feature Board" <owner/repo>
```
Built-in **Status** (Todo/In Progress/Done) plus **Owner** and **Worktree** fields.

## 9. Running multiple repositories
Keep one config per repo and run an agent instance per config:
```bash
cp /home/ubuntu/.orca-hackathon/config /home/ubuntu/.orca-hackathon/<name>.env
# edit it for the other repo, then:
ORCA_HACKATHON_CONFIG=/home/ubuntu/.orca-hackathon/<name>.env /home/ubuntu/bin/orca-merge-agent
```
For continuous multi-repo operation, add a systemd instance per config.

## 10. Operations
- **Access links:** on the host, `orca serve` prints a pairing URL + web-client URL; give each
  teammate one (revocable per client). Treat them like passwords.
- **systemd:** `orca-serve.service`, `orca-merge-agent.service` + `.timer`.
- **Upgrades:** `orca-ide` auto-updates; agents update via npm/their installers.
- **Backups:** back up `/home/ubuntu/.config/orca/profiles/` (settings/state) and the repo.

## 11. Troubleshooting
See `docs/09-troubleshooting.md`. Common: non-interactive PATH (`~/.local/bin`), `opencode run`
needs `--standalone`, stale pairing links (restart rotates them), merge agent logs under
`~/.orca-merge/log`.

## 12. Reference
- **Config:** `/home/ubuntu/.orca-hackathon/config` → `REPO`, `BASE_BRANCH`, `REPO_DIR`.
- **Labels:** `merge-ready`, `merge-conflict`, `needs-author-input`.
- **Resolver exit codes:** `0` resolved/no-conflict, `10` escalated, `2` error.
- **Scripts:** `setup-new-repo.sh`, `github/configure-repo.sh`, `github/setup-board.sh`,
  `merge-agent/*`, `person/*`.
