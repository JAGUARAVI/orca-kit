# 02 — Hosts & access

## Pair an Orca client
- Desktop: Settings → Remote Orca Servers → Add Server → paste the link in
  `~/.orca-access-link` (first line).
- Browser: open the second line of `~/.orca-access-link` (over Tailscale).
Access is Tailscale-only; the endpoint is not reachable from the public internet.
Each paired client gets a revocable grant (host: Settings → Shared Server Access).

## Service
- `orca-serve.service` runs `xvfb-run orca-ide serve --port 6768 --pairing-address <tailscale-ip>`.
- Restart regenerates the pairing offer: `sudo systemctl restart orca-serve`.
- Logs: `sudo journalctl -u orca-serve -f`.

## Remote worktrees over SSH (alternative)
Add the host under Settings → SSH and pick it under "Run on".
