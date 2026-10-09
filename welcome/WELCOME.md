# Orca Multi-Agent Setup — Team Welcome

Welcome! This explains what we set up, how it works, and how you use it.
Short version: `SUMMARY.md`. Ready-to-forward invites: `INVITE.md` and `invites/<name>.md`.

## 1. The 30-second version
We run a shared **Orca** runtime on a cloud host. From your laptop (or phone) you connect to it
over Tailscale and drive a fleet of coding agents. Each feature gets its own git **worktree** so
agents never collide. Work lands through **pull requests**, and an **automated merge agent**
serializes merges, resolves conflicts when it safely can, and asks the author when it can't.
A shared **GitHub Project board** tracks features and decisions.

## 2. What exists (the pieces)
- **Host**: one always-on AWS Lightsail machine (Ubuntu 24.04). It owns all files, worktrees, and agent processes.
- **Orca runtime**: a headless Orca server (`orca-serve.service`). Clients connect to it; the host does the work.
- **Agents installed**: Claude Code, Codex, **OpenCode v2** (`opencode2`), Cursor CLI — each with per-person profiles.
- **Model**: OpenCode is backed by **DeepSeek-V4.1-Flash** via **Fireworks on Microsoft Foundry**, with cost tracking.
- **Repository**: `<owner>/<repo>` on GitHub (private). PRs + required checks + auto-merge.
- **Merge agent**: runs on the host, lands ready PRs, resolves conflicts, escalates to authors.
- **Board**: a GitHub Project for features/decisions: https://github.com/users/<owner>/projects/1
- **Network**: everything private over Tailscale. The Orca port is not reachable from the public internet.

## 3. How it works (the model)
- **Host/client**: the host holds repos, worktrees, terminals, and agent processes. Your app is the UI.
  This means agents keep running when your laptop sleeps, and everyone shares one workspace.
- **Worktrees**: every task is a separate `git worktree` (its own branch and folder). Parallel agents
  can edit the same file in different worktrees without stepping on each other.
- **Per-person credentials**: each person has a profile (`~/.orca-keys/<Name>.env`) and wrappers
  (`<Name>-claude`, `<Name>-opencode2`, ...). When Orca launches an agent in a worktree, a router reads
  the worktree's `.orca-owner` file to pick that person's env and (for Claude) their own config dir.
  So your agents use **your** logins/keys, not someone else's.
- **Merge agent**: a background service checks PRs labeled `merge-ready`, updates their branches onto
  `main`, arms auto-merge, and on conflicts either resolves them (per policy) or escalates a question
  to the PR's author agent. See section 7.
- **Board**: the shared surface for "what are we building and what did we decide".

## 4. Get connected (one-time)
1. **Join the Tailscale tailnet** (install Tailscale; accept the invite). Everything is private to the tailnet.
2. **Open Orca** (desktop app) → Settings → Remote Orca Servers → **Add Server** → paste the access link
   (ask Avi for `~/.orca-access-link`; treat it like a password). Or just open the **browser client** link.
3. **Verify**: you should see the `<repo>` repo and shared worktrees.

## 5. Your profile
- Env: `~/.orca-keys/<Name>.env` (API keys for OpenCode/Codex/Cursor, and your Claude config dir).
- Wrappers: `<Name>-claude`, `<Name>-opencode2`, `<Name>-codex`, `<Name>-cursor`.
- Claude: each person has an isolated `CLAUDE_CONFIG_DIR` (`.orca-people/<Name>/claude`) so logins don't collide.
  First use: run `<Name>-claude` and log in.
- **Set your identity per worktree**: `echo <Name> > .orca-owner` in the worktree. Orca-launched agents
  then use your credentials automatically.

## 6. Daily workflow
```bash
# create an isolated workspace for your task (Orca UI or CLI)
orca-ide worktree create --name feat-x --agent opencode2 --prompt "implement X" --json

# tell the router whose credentials to use
echo <Name> > .orca-owner

# work with your agent (in a terminal in the worktree)
<Name>-opencode2         # or <Name>-claude, etc.

# ship
git add -A && git commit -m "feat: X" && git push -u origin <branch>
gh pr create --fill --base main
gh pr edit <n> --add-label merge-ready     # hand it to the merge agent
```
Watch the merge agent: `tail -f ~/.orca-merge/log/merge-agent.log`.

## 7. The merge agent (how merges happen)
- Looks at PRs labeled `merge-ready`, oldest first.
- Updates the branch onto `main` and enables GitHub auto-merge (merges when required checks pass).
- On a conflict it uses an LLM agent to resolve **only if safe**:
  - disjoint edits → auto
  - append-only logs (`*.jsonl`) → union
  - generated files → regenerate
  - **semantic overlap** (same constant/logic) or frozen paths → **escalate**
- **Escalation**: it writes a question to `~/.orca-merge/questions/<pr>.json`, labels the PR
  `merge-conflict` + `needs-author-input`, and comments. The **author agent** answers:
  `orca-author-respond <author-label> <pr>` → the merge agent then applies the answer and merges.
- Proven: two agents editing the same list were auto-merged; a `RATE=2` vs `RATE=5` conflict was
  escalated to the author, answered, and merged.

## 8. The board (decisions)
https://github.com/users/<owner>/projects/1
- One card per feature or decision. Fields: **Status** (Todo/In Progress/Done), **Owner**, **Worktree**.
- Use it to agree on what we build and settle disagreements; reference the card in your PR.

## 9. Rules of the road
- One worktree per feature; set `.orca-owner`; put your name as **Owner** on the board card.
- **Never push to `main`** — it's protected; everything goes via PR + `merge-ready`.
- Keep API keys in your own `~/.orca-keys/<Name>.env`; don't share personal keys.
- Don't renumber/force-push others' branches.
- Keep secrets out of git; `.orca-owner` is gitignored.

## 10. Where to look
- Technical detail: `~/orca-docs/` (start at `00-index.md`).
- Logs: `~/.orca-merge/log/`, `sudo journalctl -u orca-serve`, `sudo journalctl -u orca-merge-agent`.
- Master index: `~/ORCA-SETUP.md`.
- Stuck? `~/orca-docs/09-troubleshooting.md`.
