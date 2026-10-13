# Invite — Orca multi-agent setup

You're invited to our shared **Orca multi-agent workspace**. Here's everything you need.

## 1) Join Tailscale (private network)
Install Tailscale: https://tailscale.com/download and accept the tailnet invite (ask the admin).
Everything runs over Tailscale; nothing is exposed to the public internet.

## 2) Connect Orca
- **Desktop**: Orca → Settings → Remote Orca Servers → Add Server → paste your access link (secret).
- **Browser** (no install): open the browser-client link.

> Generate these on the host (`orca serve` prints a pairing URL and a web-client URL) and hand them
> out privately. **Treat an access link like a password** — never commit it, screenshot it, or paste
> it into a prompt. Restarting the runtime rotates them. See `GUIDE.md` → "Access links".

## 3) Your login
- Claude Code: run `<YourName>-claude` once to log in (your own isolated account).
- Other agents: add your keys to `~/.orca-keys/<YourName>.env`.

## 4) Use it
```
orca worktree create --name feat-x --agent opencode2 --prompt "implement X" --json
echo <YourName> > .orca-owner     # your agents use your credentials
# work, then:
git push -u origin <branch> && gh pr create --fill --base main
gh pr edit <n> --add-label merge-ready
```

## 5) Board
Features/decisions: a GitHub Project board (see `docs/10-board-and-agents.md`).

Full guide: `~/orca-welcome/WELCOME.md` · Short: `~/orca-welcome/SUMMARY.md` · Docs: `~/orca-docs/00-index.md`

Questions → your workspace admin.