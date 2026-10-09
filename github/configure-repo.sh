#!/usr/bin/env bash
set -uo pipefail
REPO=${1:?usage: configure-repo.sh <owner/repo> [base_branch]}; BRANCH=${2:-main}
gh api -X PATCH "repos/$REPO" -f allow_auto_merge=true >/dev/null 2>&1 || true
RSID=$(gh api "repos/$REPO/rulesets" --jq '.[]|select(.name=="main-protection")|.id' 2>/dev/null | head -1)
BODY=$(cat <<JSON
{"name":"main-protection","target":"branch","enforcement":"active","conditions":{"ref_name":{"include":["refs/heads/$BRANCH"],"exclude":[]}},"rules":[{"type":"pull_request","parameters":{"required_approving_review_count":0,"allowed_merge_methods":["squash","merge","rebase"]}},{"type":"required_status_checks","parameters":{"strict_required_status_checks_policy":true,"required_status_checks":[{"context":"checks"}]}}]}
JSON
)
if [ -z "$RSID" ]; then echo "$BODY" | gh api -X POST "repos/$REPO/rulesets" --input - >/dev/null && echo "ruleset created"; else echo "$BODY" | gh api -X PUT "repos/$REPO/rulesets/$RSID" --input - >/dev/null && echo "ruleset updated"; fi
