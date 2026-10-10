#!/usr/bin/env bash
# Set up the Orca multi-agent flow in an EXISTING local repo (no clone, GitHub optional).
# Usage: setup-existing-repo.sh <local_dir> [base_branch]
set -uo pipefail
DIR=${1:?usage: setup-existing-repo.sh <local_dir> [base_branch]}
BRANCH=${2:-main}
DIR=$(cd "$DIR" && pwd)
KIT=$(cd "$(dirname "$0")" && pwd)
NAME=$(basename "$DIR")
export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$PATH"

echo "== Orca kit setup (existing repo): $NAME -> $DIR (base $BRANCH) =="
[ -d "$DIR/.git" ] || { echo "not a git repo: $DIR" >&2; exit 1; }
cd "$DIR"

mkdir -p .github/workflows templates docs/orca-kit
[ -f .github/workflows/ci.yml ] || cp "$KIT/github/ci.yml" .github/workflows/ci.yml
[ -f AGENTS.md ] || cp "$KIT/templates/AGENTS.md" AGENTS.md
for f in SPEC ADR AGENTS TASK-BRIEF; do [ -f "templates/$f.md" ] || cp "$KIT/templates/$f.md" "templates/$f.md"; done
cp -rn "$KIT/docs/." docs/orca-kit/ 2>/dev/null || true
git add -A
git -c user.name="$(git config user.name || echo orca)" -c user.email="$(git config user.email || echo orca@local)" \
  commit -qm "chore: apply Orca kit (AGENTS.md, templates, CI, docs)" 2>/dev/null || echo "(scaffold already committed)"

mkdir -p "$HOME/.orca-hackathon"
CFG="$HOME/.orca-hackathon/$NAME.env"
REPO=""
if git remote get-url origin >/dev/null 2>&1; then
  REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner 2>/dev/null || true)
fi
cat > "$CFG" <<CFGEOF
REPO=$REPO
BASE_BRANCH=$BRANCH
REPO_DIR=$DIR
CFGEOF
echo "wrote $CFG (REPO=${REPO:-<none>})"

orca-ide repo add --path "$DIR" --json >/dev/null 2>&1 || true
orca-ide repo set-base-ref --repo "path:$DIR" --ref "$BRANCH" --json >/dev/null 2>&1 || true
echo "registered with Orca"

if [ -n "$REPO" ] && gh auth status >/dev/null 2>&1; then
  for l in merge-ready merge-conflict needs-author-input; do gh label create "$l" --force >/dev/null 2>&1 || true; done
  bash "$KIT/github/configure-repo.sh" "$REPO" "$BRANCH" || true
  if [ -f /etc/systemd/system/orca-merge-agent@.timer ]; then
    sudo -n systemctl enable --now "orca-merge-agent@$NAME.timer" >/dev/null 2>&1 || true
    echo "enabled merge-agent instance: orca-merge-agent@$NAME.timer"
  fi
else
  echo "No GitHub remote yet: skipped labels, protection, merge agent."
  echo "After adding a remote, re-run: $KIT/setup-existing-repo.sh \"$DIR\" $BRANCH"
fi
echo "== done =="
