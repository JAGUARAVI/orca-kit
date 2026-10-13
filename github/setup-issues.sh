#!/usr/bin/env bash
# setup-issues.sh — one command to stand up the issue system for a repo:
#   labels  ->  milestones/phases  ->  task issues from docs/tasks  ->  dependency links
#
# Idempotent: re-running only creates what is missing and refreshes dependency blocks.
# Uses the person's `gh` wrapper so issues are authored under the right identity.
#
# Usage:
#   github/setup-issues.sh <owner/repo> [--root <repo-path>] [--deps docs/tasks/deps.json]
#                          [--phases P0 P1 P2] [--gh <Name>-gh] [--dry-run]
#
# Examples:
#   github/setup-issues.sh IIIT-ECell/megathon26-megathon-gs --root . --phases P0 P1 P2 --gh Avi-gh
#
set -uo pipefail

REPO=""; ROOT="."; DEPS=""; PHASES="P0 P1"; GH="gh"; DRY=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --root)   ROOT="$2"; shift 2 ;;
    --deps)   DEPS="$2"; shift 2 ;;
    --phases) PHASES="$2"; shift 2 ;;
    --gh)     GH="$2"; shift 2 ;;
    --dry-run) DRY=1; shift ;;
    -h|--help) sed -n '2,18p' "$0"; exit 0 ;;
    *) REPO="$1"; shift ;;
  esac
done
[[ -n "$REPO" ]] || { echo "usage: setup-issues.sh <owner/repo> [--root ...] [--gh <Name>-gh]" >&2; exit 2; }
HERE=$(cd "$(dirname "$0")" && pwd)

echo "== repo: $REPO   root: $ROOT   phases: $PHASES   identity: $GH =="

echo
echo "== 1/4 labels =="
bash "$HERE/labels.sh" "$REPO"

echo
echo "== 2/4 phases as milestones =="
for p in $PHASES; do
  if [[ $DRY = 1 ]]; then echo "DRY: create milestone $p"; continue; fi
  if "$GH" api "repos/$REPO/milestones" --jq '.[].title' 2>/dev/null | grep -qx "$p"; then
    echo "milestone: $p (exists)"
  else
    "$GH" api -X POST "repos/$REPO/milestones" -f title="$p" -f state=open >/dev/null 2>&1 \
      && echo "milestone: $p (created)" || echo "milestone: $p (skipped)"
  fi
done

echo
echo "== 3/4 task issues from docs/tasks =="
ARGS=(--repo "$REPO" --root "$ROOT" --phases $PHASES --gh "$GH")
[[ -n "$DEPS" ]] && ARGS+=(--deps "$DEPS")
[[ $DRY = 1 ]] && ARGS+=(--dry-run)
python3 "$HERE/create-task-issues.py" "${ARGS[@]}"

echo
echo "== 4/4 install the auto-unblock Action =="
if [[ $DRY = 1 ]]; then
  echo "DRY: copy task-reconcile.yml + reconcile-task-issues.py into .github"
else
  mkdir -p "$ROOT/.github/workflows" "$ROOT/.github/scripts"
  cp "$HERE/task-reconcile.yml"          "$ROOT/.github/workflows/task-reconcile.yml"
  cp "$HERE/reconcile-task-issues.py"    "$ROOT/.github/scripts/reconcile-task-issues.py"
  # the job needs issues:write -> ensure Actions can write
  "$GH" api -X PUT "repos/$REPO/actions/permissions/workflow" \
    -f default_workflow_permissions=write >/dev/null 2>&1 \
    && echo "Actions workflow permissions = write" || echo "(set workflow permissions manually in Settings)"
  echo "installed .github/workflows/task-reconcile.yml + .github/scripts/reconcile-task-issues.py"
fi

echo
echo "done. Issues: https://github.com/$REPO/issues   Labels: https://github.com/$REPO/labels"