# 08 — Runbook

## Add a feature (worktree + agent)
```bash
orca-ide worktree create --name feat-x --agent opencode2 --prompt "implement X" --json
# or in a worktree terminal: Avi-opencode2
git add -A && git commit -m "feat: X" && git push -u origin <branch>
gh pr create --fill --base main
gh pr edit <n> --add-label merge-ready
```

## Watch the merge agent
```bash
tail -f /home/ubuntu/.orca-merge/log/merge-agent.log
systemctl list-timers orca-merge-agent.timer
systemctl start orca-merge-agent.service     # run now
gh pr list --label merge-ready --state open
```

## Escalate/answer
```bash
cat ~/.orca-merge/questions/<pr>.json
orca-author-respond <author-label> <pr>
```

## Raise approvals to 1 (for the team)
```bash
gh api -X PUT repos/<owner>/<repo>/rulesets/24813857 --input - <<'J'
{"name":"main-protection","target":"branch","enforcement":"active",
 "conditions":{"ref_name":{"include":["refs/heads/main"],"exclude":[]}},
 "rules":[{"type":"pull_request","parameters":{"required_approving_review_count":1,"allowed_merge_methods":["squash","merge","rebase"]}},
 {"type":"required_status_checks","parameters":{"strict_required_status_checks_policy":true,"required_status_checks":[{"context":"checks"}]}}]}
J
```

## Optional: native merge queue
Requires a **public** repo (unavailable on private/Free). Make the repo public, then
add the `merge_queue` rule to the ruleset. Not required — the merge agent covers it.

## Add a teammate
1. Add them to the Tailscale tailnet.
2. Send the link in `~/.orca-access-link` (desktop or browser).
3. `orca-keys-add <Name>` + fill keys.
