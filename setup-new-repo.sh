#!/usr/bin/env bash
# Bootstrap the Orca multi-agent flow for ANY repository.
# Usage: setup-new-repo.sh <owner/repo> [base_branch] [local_dir]
set -uo pipefail
. "$(dirname "$0")/lib/orca-kit.sh"

REPO=${1:?usage: setup-new-repo.sh <owner/repo> [base_branch] [local_dir]}
BRANCH=${2:-${BASE_BRANCH:-main}}
NAME=${REPO##*/}
DIR=${3:-${WORKSPACE_ROOT:-$HOME}/$NAME}
KIT=$(cd "$(dirname "$0")" && pwd)

echo "== Orca setup: $REPO (branch $BRANCH) -> $DIR =="
[ -d "$DIR/.git" ] || git clone "https://github.com/$REPO.git" "$DIR"
cd "$DIR"; git fetch -q origin
git checkout -q "$BRANCH" 2>/dev/null || git checkout -q -B "$BRANCH" "origin/$BRANCH"

mkdir -p "$HACKATHON_DIR"
cat > "$HACKATHON_DIR/config" <<CFG
REPO=$REPO
BASE_BRANCH=$BRANCH
REPO_DIR=$DIR
CFG
echo "wrote $HACKATHON_DIR/config"

mkdir -p .github/workflows
[ -f .github/workflows/ci.yml ] || cp "$KIT/github/ci.yml" .github/workflows/ci.yml
git add -A
if [ -n "$(git diff --cached --name-only)" ]; then
  git commit -qm "ci: add required checks workflow"
  if ! git push -q origin "$BRANCH" 2>/dev/null; then
    git checkout -q -b chore/orca-ci
    git push -q -u origin chore/orca-ci
    "$GH" pr create --base "$BRANCH" --head chore/orca-ci --title "ci: add required checks workflow" --body "Orca bootstrap" >/dev/null 2>&1 || true
    PRN=$("$GH" pr list --head chore/orca-ci --json number --jq '.[0].number' 2>/dev/null)
    [ -n "$PRN" ] && "$GH" pr merge "$PRN" --squash >/dev/null 2>&1 || true
    git checkout -q "$BRANCH"
  fi
fi
for l in merge-ready merge-conflict needs-author-input; do "$GH" label create "$l" --force >/dev/null 2>&1 || true; done
bash "$KIT/github/configure-repo.sh" "$REPO" "$BRANCH"

mkdir -p "$BIN_DIR"
cp "$KIT/merge-agent/orca-merge-agent"      "$BIN_DIR/orca-merge-agent"
cp "$KIT/merge-agent/orca-merge-resolve.sh" "$BIN_DIR/orca-merge-resolve.sh"
cp "$KIT/merge-agent/orca-author-respond"   "$BIN_DIR/orca-author-respond"
chmod +x "$BIN_DIR"/orca-merge-* "$BIN_DIR"/orca-author-respond
cp "$KIT/person/orca-route" "$KIT"/person/orca-route-* "$LOCAL_BIN/" 2>/dev/null || true
chmod +x "$LOCAL_BIN"/orca-route* 2>/dev/null || true

orca-ide repo add --path "$DIR" --json >/dev/null 2>&1 || true
orca-ide repo set-base-ref --repo "path:$DIR" --ref "origin/$BRANCH" >/dev/null 2>&1 || true
echo "== done =="
echo "merge agent -> $DIR; run: $BIN_DIR/orca-merge-agent"
echo "board: bash $KIT/github/setup-board.sh <owner> \"Feature Board\" $REPO"