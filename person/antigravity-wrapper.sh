#!/usr/bin/env bash
# Template: per-person Antigravity (agy) wrapper with an isolated HOME.
# Install as ~/.local/bin/<Name>-antigravity and chmod +x.
#   HOME      -> ~/.orca-people/<Name>/antigravity  (settings + credentials, per person)
#   GH_CONFIG_DIR / GIT_* come from the person's env (~/.orca-keys/<Name>.env)
set -euo pipefail
NAME="${1:-Name}"
P="$HOME/.orca-people/$NAME/antigravity"
export PATH="$HOME/.local/bin:$PATH"
[ -f "$HOME/.orca-keys/$NAME.env" ] && { set -a; . "$HOME/.orca-keys/$NAME.env"; set +a; }
export HOME="$P"
mkdir -p "$HOME/.gemini/antigravity-cli"
exec "$HOME/.local/bin/agy" "$@" 2>/dev/null || exec agy "$@"
