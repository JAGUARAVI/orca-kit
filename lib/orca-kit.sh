# shellcheck shell=bash
# orca-kit common — source this from any kit script:
#   . "$(dirname "$0")/../lib/orca-kit.sh"    # adjust depth
#
# It loads, in order of precedence:
#   1. $ORCA_KIT_ENV (explicit file)          — highest
#   2. ~/.orca-kit.env  or  /etc/orca-kit.env
#   3. orca-kit.env.example (the defaults)
# then fills any remaining gap with computed defaults. No secrets here; see doc 05 for keys.

_orca_kit_self="${BASH_SOURCE[0]:-$0}"
_orca_kit_dir="$(cd "$(dirname "$_orca_kit_self")" && pwd)"

for _f in \
  "${ORCA_KIT_ENV:-}" \
  "$HOME/.orca-kit.env" \
  "/etc/orca-kit.env" \
  "$_orca_kit_dir/orca-kit.env.example" \
  "$_orca_kit_dir/../orca-kit.env.example" ; do
  [ -n "$_f" ] && [ -f "$_f" ] && { . "$_f"; break; }
done

# computed defaults (only if unset by the config or the environment)
: "${KIT_USER:=$(id -un 2>/dev/null || echo "${USER:-user}")}"
: "${KIT_HOME:=$HOME}"
: "${KIT_OWNER:=$KIT_USER}"
: "${KIT_DIR:=$KIT_HOME/orca-kit}"
: "${DOCS_DIR:=$KIT_HOME/orca-docs}"
: "${WELCOME_DIR:=$KIT_HOME/orca-welcome}"
: "${BIN_DIR:=$KIT_HOME/bin}"
: "${LOCAL_BIN:=$KIT_HOME/.local/bin}"
: "${OPENCODE_BIN_DIR:=$KIT_HOME/.opencode/bin}"
: "${MERGE_DIR:=$KIT_HOME/.orca-merge}"
: "${KEYS_DIR:=$KIT_HOME/.orca-keys}"
: "${PEOPLE_DIR:=$KIT_HOME/.orca-people}"
: "${HACKATHON_DIR:=$KIT_HOME/.orca-hackathon}"
: "${MODEL:=fireworks-azure/Avi-DeepSeek-V4.1-Flash}"
: "${AGENT_NAME:=opencode2}"
: "${AGENT_BIN:=$LOCAL_BIN/$AGENT_NAME}"
: "${GH:=gh}"
: "${BASE_BRANCH:=main}"
: "${RUNNER_DIR:=$KIT_HOME/actions-runner}"
: "${RUNNER_LABELS:=self-hosted,linux,x64,orca-vm}"
: "${RUNNER_PORTS:=4173 4174}"

# PATH so wrappers/binaries resolve regardless of the caller's environment
case ":$PATH:" in
  *":$LOCAL_BIN:"*) ;;   *) PATH="$LOCAL_BIN:$PATH" ;;
esac
case ":$PATH:" in
  *":$OPENCODE_BIN_DIR:"*) ;; *) PATH="$OPENCODE_BIN_DIR:$PATH" ;;
esac
: "${BIN_DIR:=$KIT_HOME/bin}"
case ":$PATH:" in
  *":$BIN_DIR:"*) ;; *) PATH="$BIN_DIR:$PATH" ;;
esac
export PATH

# Resolve the repo slug from an explicit value or the checkout's origin remote.
orca_kit_repo_slug(){
  if [ -n "${REPO_SLUG:-}" ]; then printf '%s' "$REPO_SLUG"; return; fi
  local root="${1:-${REPO_DIR:-$PWD}}"
  git -C "$root" remote get-url origin 2>/dev/null \
    | sed -E 's#(git@|https?://)github.com[:/]([^/]+/[^/.]+)(\.git)?#\2#'
}
export -f orca_kit_repo_slug 2>/dev/null || true