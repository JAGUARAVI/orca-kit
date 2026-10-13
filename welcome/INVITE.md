# Invite — Orca hackathon setup

You're invited to our shared **Orca multi-agent workspace**. Here's everything you need.

## 1) Join Tailscale (private network)
Install Tailscale: https://tailscale.com/download and accept the tailnet invite (ask Avi).
Everything runs over Tailscale; nothing is exposed to the public internet.

## 2) Connect Orca
- **Desktop**: Orca → Settings → Remote Orca Servers → Add Server → paste this link (keep it secret):
```
orca://pair?code=eyJ2IjoyLCJlbmRwb2ludCI6IndzOi8vMTI3LjAuMC4xOjY3NjgiLCJkZXZpY2VUb2tlbiI6ImZjMmYzNmZiOTg2OWM4ZTQwOTQxZDQ2ZDFkODI2ZmEzMjdiZjRlZjA3MWYzNWM1ZiIsInB1YmxpY0tleUI2NCI6Im5ROHJONGJLalkydWUxUGlkV0orUEN1Y3lLV05WNUN1Rm10OFpyWStQMU09IiwicGFpcmVkRGV2aWNlSWQiOiIwM2Y5ZGJjNC0zYmNjLTQ2NWUtYjg2MC03YTZkMzRlMWNiNDYiLCJzY29wZSI6InJ1bnRpbWUifQ
```
- **Browser** (no install): open:
```
http://127.0.0.1:6768/web-index.html#pairing=orca%3A%2F%2Fpair%3Fcode%3DeyJ2IjoyLCJlbmRwb2ludCI6IndzOi8vMTI3LjAuMC4xOjY3NjgiLCJkZXZpY2VUb2tlbiI6ImZjMmYzNmZiOTg2OWM4ZTQwOTQxZDQ2ZDFkODI2ZmEzMjdiZjRlZjA3MWYzNWM1ZiIsInB1YmxpY0tleUI2NCI6Im5ROHJONGJLalkydWUxUGlkV0orUEN1Y3lLV05WNUN1Rm10OFpyWStQMU09IiwicGFpcmVkRGV2aWNlSWQiOiIwM2Y5ZGJjNC0zYmNjLTQ2NWUtYjg2MC03YTZkMzRlMWNiNDYiLCJzY29wZSI6InJ1bnRpbWUifQ
```

## 3) Your login
- Claude Code: run `<YourName>-claude` once to log in (your own isolated account).
- Other agents: add your keys to `~/.orca-keys/<YourName>.env` (Avi can help).

## 4) Use it
```
orca-ide worktree create --name feat-x --agent opencode2 --prompt "implement X" --json
echo <YourName> > .orca-owner     # your agents use your credentials
# work, then:
git push -u origin <branch> && gh pr create --fill --base main
gh pr edit <n> --add-label merge-ready
```

## 5) Board
Features/decisions: https://github.com/users/JAGUARAVI/projects/1

Full guide: `~/orca-welcome/WELCOME.md` · Short: `~/orca-welcome/SUMMARY.md` · Docs: `~/orca-docs/00-index.md`

Questions → Avi.
