#!/usr/bin/env bash
# Bootstrap the Orca hackathon flow for ANY repository.
# Usage: setup-new-repo.sh <owner/repo> [base_branch] [local_dir]
set -uo pipefail
REPO=${1:?usage: setup-new-repo.sh <owner/repo> [base_branch] [local_dir]}
BRANCH=${2:-main}
NAME=${REPO##*/}
DIR=${3:-/srv/$NAME}
KIT=$(cd "$(dirname "$0")" && pwd)
export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$PATH"
echo "== Orca hackathon setup: $REPO (branch $BRANCH) -> $DIR =="
[ -d "$DIR/.git" ] || git clone "https://github.com/$REPO.git" "$DIR"
cd "$DIR"; git fetch -q origin
git checkout -q "$BRANCH" 2>/dev/null || git checkout -q -B "$BRANCH" "origin/$BRANCH"
mkdir -p /home/ubuntu/.orca-hackathon
cat > /home/ubuntu/.orca-hackathon/config <<CFG
REPO=$REPO
BASE_BRANCH=$BRANCH
REPO_DIR=$DIR
CFG
echo "wrote /home/ubuntu/.orca-hackathon/config"
mkdir -p .github/workflows
[ -f .github/workflows/ci.yml ] || cp "$KIT/github/ci.yml" .github/workflows/ci.yml
git add -A
if [ -n "$(git diff --cached --name-only)" ]; then
  git commit -qm "ci: add required checks workflow"
  if ! git push -q origin "$BRANCH" 2>/dev/null; then
    git checkout -q -b chore/orca-ci
    git push -q -u origin chore/orca-ci
    gh pr create --base "$BRANCH" --head chore/orca-ci --title "ci: add required checks workflow" --body "Orca hackathon bootstrap" >/dev/null 2>&1 || true
    PRN=$(gh pr list --head chore/orca-ci --json number --jq '.[0].number' 2>/dev/null)
    [ -n "$PRN" ] && gh pr merge "$PRN" --squash >/dev/null 2>&1 || true
    git checkout -q "$BRANCH"
  fi
fi
for l in merge-ready merge-conflict needs-author-input; do gh label create "$l" --force >/dev/null 2>&1 || true; done
bash "$KIT/github/configure-repo.sh" "$REPO" "$BRANCH"
mkdir -p /home/ubuntu/bin
cp "$KIT/merge-agent/orca-merge-agent" /home/ubuntu/bin/orca-merge-agent
cp "$KIT/merge-agent/orca-merge-resolve.sh" /home/ubuntu/bin/orca-merge-resolve.sh
cp "$KIT/merge-agent/orca-author-respond" /home/ubuntu/bin/orca-author-respond
chmod +x /home/ubuntu/bin/orca-merge-* /home/ubuntu/bin/orca-author-respond
orca-ide repo add --path "$DIR" --json >/dev/null 2>&1 || true
orca-ide repo set-base-ref --repo "path:$DIR" --ref "origin/$BRANCH" >/dev/null 2>&1 || true
echo "== done =="
echo "merge agent now points at $DIR; run: /home/ubuntu/bin/orca-merge-agent"
echo "board: bash $KIT/github/setup-board.sh <owner> \"Feature Board\" $REPO"
