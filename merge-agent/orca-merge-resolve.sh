#!/usr/bin/env bash
# Resolve one conflicting PR with an LLM agent, or escalate to its author.
# Records combined authors (for Co-authored-by credit) in $MERGE_DIR/coauthors/<pr>.txt.
# Exit: 0 resolved/no-conflict, 10 escalated, 2 setup error.
set -uo pipefail
CFG="${ORCA_HACKATHON_CONFIG:-/home/ubuntu/.orca-hackathon/config}"
[ -f "$CFG" ] && { set -a; . "$CFG"; set +a; }
REPO_DIR=${REPO_DIR:-/srv/orca-demo}
BASE_BRANCH=${BASE_BRANCH:-main}
MERGE_DIR=${MERGE_DIR:-/home/ubuntu/.orca-merge}
MODEL=${MODEL:-fireworks-azure/Avi-DeepSeek-V4.1-Flash}
AGENT=${AGENT:-/home/ubuntu/.local/bin/Avi-opencode2}
PR=$1; shift || true
GUIDANCE=""; [ "${1:-}" = "--guidance" ] && GUIDANCE="${2:-}"
head=$(gh pr view "$PR" --json headRefName --jq .headRefName)
authors=$(gh pr view "$PR" --json labels --jq '[.labels[].name|select(startswith("agent:"))]|join(",")')
work="$MERGE_DIR/work/$PR"
git -C "$REPO_DIR" worktree prune >/dev/null 2>&1 || true
rm -rf "$work"
git -C "$REPO_DIR" fetch -q origin
git -C "$REPO_DIR" worktree add -f "$work" "origin/$head" >/dev/null 2>&1 || { echo "worktree setup failed" >&2; exit 2; }
cd "$work"; git fetch -q origin
if GIT_EDITOR=true git rebase "origin/$BASE_BRANCH" >"/tmp/rb.$PR.log" 2>&1; then echo "NO_CONFLICT"; exit 0; fi
mapfile -t files < <(git diff --name-only --diff-filter=U)
echo "conflicting files: ${files[*]}" >&2

# --- who contributed to this PR? (for Co-authored-by credit) ---
# Credit ONLY the people who actually made commits in THIS PR (merge-base..head).
# Base-branch authors who happened to touch the same files are NOT credited: the
# integration is attributed to the PR's own committers.
cofile="$MERGE_DIR/coauthors/$PR.txt"; mkdir -p "$MERGE_DIR/coauthors"; : > "$cofile"
mb=$(git merge-base "origin/$BASE_BRANCH" "origin/$head" 2>/dev/null || true)
pr_log=$(git log --format='%an <%ae>' "$mb..origin/$head" 2>/dev/null | sort -u)
pr_author=$(gh pr view "$PR" --json author --jq .author.login 2>/dev/null || true)
while IFS= read -r line; do
  [ -z "$line" ] && continue
  email=$(printf '%s' "$line" | sed -n 's/.*<\(.*\)>.*/\1/p')
  if [ -n "$pr_author" ] && [ -n "$email" ] && printf '%s' "$email" | grep -qi -- "$pr_author"; then continue; fi
  printf 'Co-authored-by: %s\n' "$line" >> "$cofile"
done < <(printf '%s\n' "$pr_log" | sed '/^$/d' | sort -u)
if [ ! -s "$cofile" ]; then rm -f "$cofile"; else echo "co-authors: $(tr '\n' ';' < "$cofile")" >&2; fi

prompt="A git rebase is in progress. Conflicting files: ${files[*]}.
Resolve ONLY the git conflict markers. Preserve the intent of BOTH features; never drop one.
If a safe, unambiguous resolution does NOT exist, reply with a line starting 'ESCALATE:' then one question.
Otherwise edit the files, run 'git add', and reply exactly 'RESOLVED'."
[ -n "$GUIDANCE" ] && prompt="$prompt
An author agent's instruction for this conflict is: $GUIDANCE"
out=$(timeout 240 "$AGENT" run --standalone --auto --model "$MODEL" "$prompt" </dev/null 2>&1 | tail -10)
echo "$out" >&2
if grep -q 'RESOLVED' <<<"$out" && ! grep -rq '<<<<<<<' "${files[@]}" 2>/dev/null; then
  git add "${files[@]}" 2>/dev/null
  # credit the combined authors on the resolution commit itself
  stopped_path=$(git rev-parse --git-path rebase-merge/stopped-sha 2>/dev/null || true)
  stopped=""; [ -n "$stopped_path" ] && [ -f "$stopped_path" ] && stopped=$(cat "$stopped_path")
  if [ -n "$stopped" ] && [ -s "$cofile" ]; then
    tr=(); while IFS= read -r c; do [ -n "$c" ] && tr+=(--trailer "$c"); done < "$cofile"
    git commit -C "$stopped" "${tr[@]}" >/dev/null 2>&1 || true
  fi
  GIT_EDITOR=true git rebase --continue >/dev/null 2>&1
  git push -f -q origin "HEAD:$head" && { echo "RESOLVED"; exit 0; }
  echo "push failed" >&2; exit 2
fi
q=$(grep -m1 'ESCALATE:' <<<"$out" | sed 's/^.*ESCALATE://')
mkdir -p "$MERGE_DIR/questions"
python3 - "$PR" "$head" "$authors" "$q" "${files[@]}" > "$MERGE_DIR/questions/$PR.json" <<'PY'
import json,sys
pr,head,authors,q,*files=sys.argv[1:]
print(json.dumps({"pr":int(pr),"head":head,"authors":[a for a in authors.split(',') if a],
 "question":q.strip() or "How should this conflict be resolved?","files":files},indent=2))
PY
echo "ESCALATED"; exit 10
