# Invite for Shaurya

Hi Shaurya — you're set up on our shared Orca workspace.

- **Claude Code**: run Shaurya-claude to log in
- **OpenCode**: blank — add keys if you want OpenCode
- Your wrappers: `Shaurya-claude`, `Shaurya-opencode2`, `Shaurya-codex`, `Shaurya-cursor`
- Your profile: `~/.orca-keys/Shaurya.env` (your keys), Claude config `~/.orca-people/Shaurya/claude`

## Join
1. Tailscale: https://tailscale.com/download (accept the tailnet invite).
2. Orca → Add Server → paste (keep secret):
```
orca://pair?code=eyJ2IjoyLCJlbmRwb2ludCI6IndzOi8vMTI3LjAuMC4xOjY3NjgiLCJkZXZpY2VUb2tlbiI6ImZjMmYzNmZiOTg2OWM4ZTQwOTQxZDQ2ZDFkODI2ZmEzMjdiZjRlZjA3MWYzNWM1ZiIsInB1YmxpY0tleUI2NCI6Im5ROHJONGJLalkydWUxUGlkV0orUEN1Y3lLV05WNUN1Rm10OFpyWStQMU09IiwicGFpcmVkRGV2aWNlSWQiOiIwM2Y5ZGJjNC0zYmNjLTQ2NWUtYjg2MC03YTZkMzRlMWNiNDYiLCJzY29wZSI6InJ1bnRpbWUifQ
```
   Browser client: http://127.0.0.1:6768/web-index.html#pairing=orca%3A%2F%2Fpair%3Fcode%3DeyJ2IjoyLCJlbmRwb2ludCI6IndzOi8vMTI3LjAuMC4xOjY3NjgiLCJkZXZpY2VUb2tlbiI6ImZjMmYzNmZiOTg2OWM4ZTQwOTQxZDQ2ZDFkODI2ZmEzMjdiZjRlZjA3MWYzNWM1ZiIsInB1YmxpY0tleUI2NCI6Im5ROHJONGJLalkydWUxUGlkV0orUEN1Y3lLV05WNUN1Rm10OFpyWStQMU09IiwicGFpcmVkRGV2aWNlSWQiOiIwM2Y5ZGJjNC0zYmNjLTQ2NWUtYjg2MC03YTZkMzRlMWNiNDYiLCJzY29wZSI6InJ1bnRpbWUifQ
3. In any worktree: `echo Shaurya > .orca-owner` so your agents use your credentials.

## Ship
```
orca-ide worktree create --name feat-x --agent opencode2 --prompt "implement X" --json
echo Shaurya > .orca-owner
# work, commit, then:
git push -u origin <branch> && gh pr create --fill --base main
gh pr edit <n> --add-label merge-ready
```
Board: https://github.com/users/JAGUARAVI/projects/1
Full guide: ~/orca-welcome/WELCOME.md

— Avi
