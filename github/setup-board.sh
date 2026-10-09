#!/usr/bin/env bash
# Create/ensure a shared GitHub Project board. Usage: setup-board.sh <owner> [title] [repo]
set -uo pipefail
OWNER=${1:?usage: setup-board.sh <owner> [title] [repo]}
TITLE=${2:-"Feature Board"}
REPO=${3:-}
NUM=$(gh project list --owner "$OWNER" --format json 2>/dev/null | jq -r --arg t "$TITLE" '.projects[]|select(.title==$t)|.number' | head -1)
[ -z "$NUM" ] || [ "$NUM" = "null" ] && { gh project create --owner "$OWNER" --title "$TITLE" >/dev/null 2>&1; NUM=$(gh project list --owner "$OWNER" --format json | jq -r --arg t "$TITLE" '.projects[]|select(.title==$t)|.number' | head -1); }
gh project field-create "$NUM" --owner "$OWNER" --name "Owner" --data-type TEXT >/dev/null 2>&1 || true
[ -n "$REPO" ] && gh project link "$NUM" --owner "$OWNER" --repo "$REPO" >/dev/null 2>&1 || true
echo "board: #$NUM"
gh project list --owner "$OWNER" --format json | jq -r --arg t "$TITLE" '.projects[]|select(.title==$t)|"\(.number) \(.title) \(.url)"'
