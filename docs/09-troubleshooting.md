# 09 — Troubleshooting

- **SSH hangs / slow**: the box may be busy; retry. Check `uptime` via a short command.
- **Orca not ready**: `systemctl status orca-serve`; `sudo journalctl -u orca-serve -n 50`.
- **Pairing link invalid**: restart rotates it; re-read `~/.orca-access-link`.
- **`opencode run` appears to hang**: v2 needs `--standalone`; run bounded and with `</dev/null`.
- **Agent "command not found"**: non-interactive shells lack `~/.local/bin`;
  `export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$PATH"`.
- **Agent has no API key**: source the person's env (`set -a; . ~/.orca-keys/<Name>.env; set +a`)
  or use their wrapper.
- **Merge agent mislabels**: check `~/.orca-merge/log/resolve-<pr>.log` (raw agent output).
- **PR stuck `merge-conflict`**: resolve via rebase or an author answer, remove the label,
  re-run `orca-merge-agent`.
