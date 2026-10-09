# 12 — Per-person GitHub auth

Each person can commit, push, and open/merge PRs as **their own GitHub account**
instead of the shared host login.

## How it works
- GitHub CLI keeps one login per `GH_CONFIG_DIR`, so each person gets
  `~/.orca-people/<Name>/gh`.
- The global git credential helper is `!/usr/bin/gh auth git-credential`, which reads
  `GH_CONFIG_DIR` **at runtime**. Exporting a person's `GH_CONFIG_DIR` therefore makes both
  `gh` and `git push` authenticate as that person.
- Commit authorship is set per person with `GIT_AUTHOR_*` / `GIT_COMMITTER_*` env vars.

The router (`orca-route`, used by every Orca-launched agent) sources the person's env from
`<worktree>/.orca-owner`, so their agents inherit the correct `GH_CONFIG_DIR` and identity
automatically — no extra steps at runtime.

## Files per person
```
~/.orca-people/<Name>/gh/            # 700: isolated gh config + token for that person
~/.orca-keys/<Name>.env              # 600: GH_CONFIG_DIR, GH_USER, GIT_* identity
~/.local/bin/<Name>-gh               # wrapper: gh with that person's GH_CONFIG_DIR
```

## Authenticate a person
```bash
# with a Personal Access Token (classic; scopes: repo, workflow, project, read:org)
orca-gh-add <Name> <PAT>

# or interactively (device-code flow)
GH_CONFIG_DIR=$HOME/.orca-people/<Name>/gh \
  gh auth login --hostname github.com --git-protocol https
```
`orca-gh-add` stores the token in the person's isolated dir, sets `GH_CONFIG_DIR`, and
records `GH_USER` + git identity (`<id>+<login>@users.noreply.github.com`) in their env.

## Verify
```bash
<Name>-gh auth status                 # shows that person's account
printf 'protocol=https\nhost=github.com\n\n' | \
  GH_CONFIG_DIR=$HOME/.orca-people/<Name>/gh git credential fill
# -> username=<login>
```

## Notes
- The **merge agent** intentionally keeps the default host login — it is the merge owner.
- New people: `orca-keys-add <Name>` already creates their gh dir + env; finish with
  `orca-gh-add <Name> <PAT>`.
- Rotate a token: re-run `orca-gh-add <Name> <newPAT>`.
- Required PAT scopes: `repo`, `workflow`, `project`, `read:org`.
