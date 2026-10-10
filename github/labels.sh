#!/usr/bin/env bash
# Create the task-workflow labels used by the kit.
# Usage: labels.sh [<owner/repo>]     (omit to use the current repo via gh)
set -uo pipefail
REPO=${1:-}
R=(); [ -n "$REPO" ] && R=(-R "$REPO")
create(){ gh label create "$1" --color "$2" --description "$3" "${R[@]}" --force >/dev/null 2>&1 && echo "label: $1"; }

# task workflow
create ready       0E8A16 "Unblocked and available to start"
create blocked     B60205 "Waiting on dependencies or a gate"
create in-progress FBCA04 "Work has started"
create review      5319E7 "Implementation is awaiting review"
create task        1D76DB "Implementation task brief"
# priorities (edit/extend to taste)
create P0          D93F0B "P0 priority"
create P1          F9D0C4 "P1 priority"
# merge flow
create merge-ready        5319E7 "Hand to the merge agent"
create merge-conflict     C2E0C6 "Merge agent hit a conflict"
create needs-author-input 1D76DB "Merge agent needs the author"
