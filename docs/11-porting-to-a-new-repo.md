# 11 — Porting to another repository

Everything here is reusable. The bootstrap kit lives at `~/orca-kit`.

## One command
```bash
/home/ubuntu/orca-kit/setup-new-repo.sh <owner/repo> [base_branch] [local_dir]
# examples
/home/ubuntu/orca-kit/setup-new-repo.sh acme/new-project main /srv/new-project
/home/ubuntu/orca-kit/setup-new-repo.sh acme/api develop /srv/api
```

## What it does
1. Clones `<owner/repo>` into `local_dir` (default `/srv/<repo-name>`).
2. Writes `/home/ubuntu/.orca-hackathon/config` with `REPO`, `BASE_BRANCH`, `REPO_DIR`.
3. Adds `.github/workflows/ci.yml` (the required `checks` job) — via PR if `main` is protected.
4. Creates labels `merge-ready`, `merge-conflict`, `needs-author-input`.
5. Enables auto-merge and configures the `main-protection` ruleset
   (strict `checks`, `0` required approvals by default).
6. Installs the merge-agent scripts into `~/bin` and registers the repo in Orca.

## Config (single source of truth)
`/home/ubuntu/.orca-hackathon/config`:
```
REPO=<owner/repo>
BASE_BRANCH=<branch>
REPO_DIR=<local checkout>
```
The merge agent and resolver read this. Change it (or re-run setup) to point at another repo.

## Running more than one repo
Set a separate config per repo and export it for a separate agent instance:
```bash
cp /home/ubuntu/.orca-hackathon/config /home/ubuntu/.orca-hackathon/api.env
# edit api.env to the other repo, then:
ORCA_HACKATHON_CONFIG=/home/ubuntu/.orca-hackathon/api.env /home/ubuntu/bin/orca-merge-agent
```
For continuous multi-repo operation, add a systemd unit per `ORCA_HACKATHON_CONFIG`.

## Board
```bash
/home/ubuntu/orca-kit/github/setup-board.sh <owner> "Feature Board" <owner/repo>
```

## Requirements
- `gh` authenticated with scopes: `repo`, `workflow`, `project`.
- The repo must allow Actions (for `ci`).
- Change the default `required_approving_review_count` (0) in `configure-repo.sh` to `1`
  when you want human review.

## Per-person profiles (same for any repo)
```bash
orca-keys-add <Name>
echo 'CLAUDE_CONFIG_DIR=/home/ubuntu/.orca-people/<Name>/claude' >> ~/.orca-keys/<Name>.env
# Then in any worktree:  echo <Name> > .orca-owner
```

## Porting checklist
1. `gh auth status` shows `repo`, `workflow`, `project`.
2. Run `setup-new-repo.sh <owner/repo>`.
3. Confirm `ci` runs on a test PR and protection is active.
4. Label a PR `merge-ready` and confirm the merge agent lands it.
5. Add people and board cards.
