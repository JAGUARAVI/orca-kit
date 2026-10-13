#!/usr/bin/env bash
# orca-runner-bootstrap.sh — install and register a GitHub Actions self-hosted runner on this VM,
# with every dependency the megathon-style CI needs. Idempotent; safe to re-run after a reboot.
#
# It exists because "the runner is missing <tool>" cost several *false* CI failures in production:
# missing node, missing gh, missing pnpm, plus Playwright's system libs. This makes one box a
# fully-provisioned runner in a single command.
#
# Usage:
#   orca-runner-bootstrap.sh <owner/repo> [--labels "self-hosted,linux,x64,orca-vm"] [--name <n>]
#                            [--gh <Name>-gh] [--dir ~/actions-runner] [--no-deps]
#
# Requires: sudo (NOPASSWD), curl, and a gh token with repo admin (to mint a registration token).
set -uo pipefail
. "$(dirname "$0")/../lib/orca-kit.sh"

REPO=""; LABELS="${RUNNER_LABELS:-self-hosted,linux,x64,orca-vm}"; NAME="orca-vm-$(hostname)"
GH="${GH:-gh}"; DIR="${RUNNER_DIR:-$HOME/actions-runner}"; DEPS=1
while [[ $# -gt 0 ]]; do
  case "$1" in
    --labels) LABELS="$2"; shift 2 ;;
    --name)   NAME="$2"; shift 2 ;;
    --gh)     GH="$2"; shift 2 ;;
    --dir)    DIR="$2"; shift 2 ;;
    --no-deps) DEPS=0; shift ;;
    -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
    *) REPO="$1"; shift ;;
  esac
done
[[ -n "$REPO" ]] || { echo "usage: orca-runner-bootstrap.sh <owner/repo> [--labels ...]" >&2; exit 2; }

say(){ printf '\n== %s ==\n' "$*"; }

if [[ $DEPS = 1 ]]; then
  say "system dependencies (node 22, pnpm, gh, Playwright/Lighthouse libs)"
  export DEBIAN_FRONTEND=noninteractive
  sudo -n apt-get update -qq
  sudo -n apt-get install -y -qq ca-certificates curl git jq unzip tar \
    libnss3 libnspr4 libdbus-1-3 libatk1.0-0t64 libatk-bridge2.0-0t64 libatspi2.0-0t64 \
    libxcomposite1 libxdamage1 libxfixes3 libxrandr2 libgbm1 libxkbcommon0 libpango-1.0-0 \
    libcairo2 libasound2t64 libcups2t64 fonts-liberation
  # node 22 (matches repo engines) if missing or wrong major
  if ! command -v node >/dev/null || [[ "$(node -v 2>/dev/null | sed 's/v\([0-9]*\).*/\1/')" != "22" ]]; then
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -n -E bash - >/dev/null
    sudo -n apt-get install -y -qq nodejs
  fi
  command -v pnpm >/dev/null || sudo -n npm install -g pnpm@12.10.1
  command -v gh   >/dev/null || {
    sudo -n mkdir -p -m 755 /etc/apt/keyrings
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | sudo -n tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
    sudo -n chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      | sudo -n tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    sudo -n apt-get update -qq && sudo -n apt-get install -y -qq gh
  }
  printf 'node=%s pnpm=%s gh=%s\n' "$(node -v)" "$(pnpm -v)" "$(gh --version | head -1)"
fi

say "actions runner at $DIR"
mkdir -p "$DIR"; cd "$DIR"
if [[ ! -f config.sh ]]; then
  VER=$(curl -sS https://api.github.com/repos/actions/runner/releases/latest | jq -r .tag_name | sed 's/^v//')
  VER=${VER:-2.338.0}
  curl -sSL -o runner.tar.gz "https://github.com/actions/runner/releases/download/v${VER}/actions-runner-linux-x64-${VER}.tar.gz"
  tar xzf runner.tar.gz && rm -f runner.tar.gz
fi
sudo -n ./bin/installdependencies.sh >/dev/null 2>&1 || true

say "register (repo-level) if not already"
if [[ -f .runner ]]; then
  echo "already registered: $(jq -r .agentName .runner 2>/dev/null || echo '?')"
else
  TOKEN=$("$GH" api -X POST "repos/$REPO/actions/runners/registration-token" --jq .token)
  ./config.sh --url "https://github.com/$REPO" --token "$TOKEN" \
    --name "$NAME" --labels "$LABELS" --work "_work" --unattended --replace
fi

say "systemd service"
if ! systemctl list-unit-files "actions.runner.*.service" --no-pager 2>/dev/null | grep -q "$(hostname)"; then
  sudo -n ./svc.sh install "$USER"
fi
sudo -n ./svc.sh start

say "status"
sudo -n ./svc.sh status 2>&1 | head -8
"$GH" api "repos/$REPO/actions/runners" \
  --jq '.runners[]|"\(.name) status=\(.status) busy=\(.busy) labels=\(.labels|map(.name)|join(","))"'