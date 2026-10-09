# Invite — Orca multi-agent setup

You're invited to our shared **Orca multi-agent workspace**.

## 1) Join Tailscale (private network)
Install https://tailscale.com/download and accept the tailnet invite.

## 2) Connect Orca
- **Desktop**: Orca → Settings → Remote Orca Servers → Add Server → paste the access link (secret).
- **Browser**: open the browser-client link.
(Generate links on the host: see GUIDE.md → "Access links". Treat them like passwords.)

## 3) Your login
- Claude Code: run `<YourName>-claude` once to log in (isolated per person).
- Other agents: add your keys to `~/.orca-keys/<YourName>.env`.

## 4) Use it
```bash
orca-ide worktree create --name feat-x --agent opencode2 --prompt "implement X" --json
echo <YourName> > .orca-owner        # your agents use your credentials
git push -u origin <branch>
gh pr create --fill --base main
gh pr edit <n> --add-label merge-ready
```

## 5) Board
See the shared GitHub Project for features/decisions.

Full guide: `GUIDE.md`.

## Your GitHub identity
So your commits/pushes/PRs use **your** account, authenticate once:
```bash
orca-gh-add <YourName> <your-PAT>   # scopes: repo, workflow, project, read:org
```
Then `echo <YourName> > .orca-owner` in your worktree. See `docs/12-per-person-github-auth.md`.
