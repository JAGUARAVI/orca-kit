#!/usr/bin/env bash
# orca-runner-health.sh — keep self-hosted runners alive and CI-safe on a shared box.
#
# Runs from a systemd timer every few minutes. It:
#   1. restarts a runner service that is enabled but not active (offline runner);
#   2. frees the CI ports (4173/4174) of stale agent `vite preview` servers, which caused
#      "http://127.0.0.1:4173 is already used" failures on the shared VM;
#   3. re-installs pnpm/node/gh if a reboot or upgrade removed them (the exact "false failure"
#      causes seen in production);
#   4. logs a one-line health summary.
set -uo pipefail
. "$(dirname "$0")/../lib/orca-kit.sh"
LOG="${LOG:-$HOME/.orca-runner-health.log}"
RUNNER_DIR="${RUNNER_DIR:-$HOME/actions-runner}"
PORTS="${RUNNER_PORTS:-${PORTS:-4173 4174}}"
log(){ echo "$(date -Is) $*" | tee -a "$LOG"; }

# 1) runner service health
if [[ -f "$RUNNER_DIR/.service" ]]; then
  svc=$(systemctl list-units 'actions.runner.*.service' --no-pager --plain 2>/dev/null | awk '{print $1}' | head -1)
  if [[ -n "$svc" ]]; then
    if [[ "$(systemctl is-enabled "$svc" 2>/dev/null)" == "enabled" && "$(systemctl is-active "$svc")" != "active" ]]; then
      log "runner $svc inactive -> restart"; sudo -n systemctl restart "$svc" || log "restart failed"
    else
      log "runner $svc ok ($(systemctl is-active "$svc"))"
    fi
  fi
fi

# 2) free CI ports from stale dev servers
for p in $PORTS; do
  if ss -ltn 2>/dev/null | grep -q ":$p "; then
    # only kill vite/preview/serve processes, never the runner itself
    pids=$(ss -ltnp 2>/dev/null | awk -v P=":$p" '$4 ~ P {print $NF}' | grep -oE 'pid=[0-9]+' | cut -d= -f2 | sort -u)
    for pid in $pids; do
      cmd=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null || true)
      case "$cmd" in
        *vite*|*preview*|*serve*) kill "$pid" 2>/dev/null && log "freed port $p (pid $pid: ${cmd:0:60})" ;;
        *) log "port $p held by non-vite pid $pid (left alone)" ;;
      esac
    done
  fi
done

# 3) toolchain self-heal
command -v node >/dev/null || log "WARN node missing"
command -v pnpm >/dev/null || { sudo -n npm install -g pnpm@12.10.1 >/dev/null 2>&1 && log "reinstalled pnpm"; }
command -v gh   >/dev/null || log "WARN gh missing (re-run orca-runner-bootstrap.sh)"