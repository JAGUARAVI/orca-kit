#!/usr/bin/env bash
# install.sh — install the kit's agent skills globally, for every agent on this host.
#
# Skills are copied to the shared dir (~/.agents/skills) and symlinked into each agent's skill
# directory so OpenCode/Claude pick them up without duplication.
#
# Usage:
#   skills/install.sh [all|<name>...]     # default: all skills in this directory
#
# Skips `_template`. Third-party skills (ponytail, orca-cli, ...) are installed separately — see
# skills/README.md.
set -uo pipefail
. "$(dirname "$0")/../lib/orca-kit.sh"

HERE="$(cd "$(dirname "$0")" && pwd)"
SHARED="${AGENTS_SKILLS_DIR:-$HOME/.agents/skills}"
OPENCODE_SKILLS="${OPENCODE_SKILLS_DIR:-$HOME/.config/opencode/skills}"
CLAUDE_SKILLS="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"

# which skills
if [ $# -eq 0 ] || [ "${1:-}" = "all" ]; then
  mapfile -t names < <(find "$HERE" -mindepth 1 -maxdepth 1 -type d ! -name '_template' -exec basename {} \; | sort)
else
  names=("$@")
fi

mkdir -p "$SHARED" "$OPENCODE_SKILLS" "$CLAUDE_SKILLS"
for n in "${names[@]}"; do
  src="$HERE/$n"
  [ -f "$src/SKILL.md" ] || { echo "skip $n (no SKILL.md)"; continue; }
  rm -rf "$SHARED/$n"; cp -r "$src" "$SHARED/$n"
  ln -sfn "$SHARED/$n" "$OPENCODE_SKILLS/$n"
  ln -sfn "$SHARED/$n" "$CLAUDE_SKILLS/$n"
  echo "installed skill: $n -> $SHARED/$n (opencode+claude symlinked)"
done
echo "done. Skills: $(ls "$SHARED" | tr '\n' ' ')"