#!/usr/bin/env bash
# board-sync.sh — mirror task-issue state onto a GitHub Project (v2) board.
#
# The board columns track the workflow labels:
#   ready / blocked / in-progress / review / done
# so nobody has to drag cards by hand.
#
# Usage:
#   github/board-sync.sh <owner> <project-number> [--repo <owner/repo>] [--gh <Name>-gh] [--dry-run]
#
# Prereqs (once):
#   github/setup-board.sh <owner> "<Title>" <owner/repo>
#   gh project field-create <n> --owner <owner> --name Worktree --data-type TEXT
#
# Requires a token with the `project` scope (the per-person wrappers have it).
set -uo pipefail

OWNER=""; NUM=""; REPO=""; GH="gh"; DRY=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="$2"; shift 2 ;;
    --gh)   GH="$2"; shift 2 ;;
    --dry-run) DRY=1; shift ;;
    -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
    *) if [[ -z "$OWNER" ]]; then OWNER="$1"; else NUM="$1"; fi; shift ;;
  esac
done
[[ -n "$OWNER" && -n "$NUM" ]] || { echo "usage: board-sync.sh <owner> <project-number> [--repo owner/repo] [--gh <Name>-gh]" >&2; exit 2; }

echo "== board #$NUM owner=$OWNER =="
# status options are the single-select field "Status" created with the project
get_item() {  # title-contains -> item id
  "$GH" project item-list "$NUM" --owner "$OWNER" --format json --limit 1000 2>/dev/null \
    | jq -r --arg t "$1" '.items[]|select(.content.title? and (.content.title|startswith($t)))|.id' | head -1
}

issues=$("$GH" issue list ${REPO:+-R "$REPO"} --state all --limit 1000 \
  --json number,title,state,labels --jq '.')
echo "$issues" | jq -c '.[]' | while read -r iss; do
  title=$(echo "$iss" | jq -r .title)
  id=$(echo "$title" | grep -oE '^\[[A-Za-z0-9]+-[0-9]+\]' | tr -d '[]' || true)
  [[ -n "$id" ]] || continue
  state=$(echo "$iss" | jq -r .state)
  labels=$(echo "$iss" | jq -r '.labels|map(.name)|join(",")')
  target="Todo"
  case "$labels" in
    *blocked*)          target="Blocked";;
    *in-progress*)      target="In Progress";;
    *review*)           target="Review";;
    *ready*)            target="Ready";;
  esac
  [[ "$state" = "CLOSED" ]] && target="Done"

  item=$(get_item "[$id]")
  [[ -n "$item" ]] || { echo "  $id: no card"; continue; }
  if [[ $DRY = 1 ]]; then echo "  DRY $id -> $target"; continue; fi
  "$GH" project item-edit --id "$item" --project-id "$("$GH" project view "$NUM" --owner "$OWNER" --format json --jq .id)" \
    --field-id "$("$GH" project field-list "$NUM" --owner "$OWNER" --format json --jq '.fields[]|select(.name=="Status")|.id')" \
    --single-select-option-id "$("$GH" project field-list "$NUM" --owner "$OWNER" --format json \
        --jq ".fields[]|select(.name==\"Status\")|.options[]|select(.name==\"$target\")|.id")" >/dev/null 2>&1 \
    && echo "  $id -> $target" || echo "  $id -> $target (failed)"
done
echo "done."