# 07 — Security

- **Network**: Orca port 6768 is firewalled to `lo` + `tailscale0` only
  (iptables, persisted). Public internet cannot reach it. SSH (22) remains open.
- **Secrets**: `/home/ubuntu/.orca-keys/*.env` and `~/.orca-access-link` are `600`.
  The Fireworks key also lives in the OpenCode auth store.
- **Agent permissions**: Orca defaults agents to Yolo
  (`--dangerously-skip-permissions` etc.). For a shared box, switch to Manual in
  Settings → Agents, or rely on worktree isolation + PR review.
- **Repo**: `main` requires the strict `checks` status; auto-merge enabled.
  Raise to 1 approval for the team (see `08-runbook.md`).
- **Firewall persistence**: `sudo netfilter-persistent save`.
