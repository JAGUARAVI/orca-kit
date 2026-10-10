# 05 — Per-person profiles (Plan B)

Each person has:
```
/home/ubuntu/.orca-keys/<Name>.env          # 600: API keys + CLAUDE_CONFIG_DIR
/home/ubuntu/.orca-people/<Name>/claude/    # 700: that person's isolated Claude Code config
/home/ubuntu/.local/bin/<Name>-{opencode2,claude,codex,cursor}
```

Add a person:
```bash
orca-keys-add <Name>
mkdir -p /home/ubuntu/.orca-people/<Name>/claude
echo 'CLAUDE_CONFIG_DIR=/home/ubuntu/.orca-people/<Name>/claude' >> /home/ubuntu/.orca-keys/<Name>.env
# then log in:  <Name> -claude   (builds that person's own config)
```

Orca-launched agents resolve the person from `<worktree>/.orca-owner`
(fallback `$ORCA_PERSON`, else Avi), source that person's env, then exec the agent.
`.orca-owner` is gitignored.

## People
| Person | Profile | OpenCode (Fireworks/Foundry) | Claude Code |
|---|---|---|---|
| Avi | `~/.orca-keys/Avi.env` | ✅ key set | config dir set (login pending) |
| Parth | `~/.orca-keys/Parth.env` | ✅ key set (shared Foundry key) | ✅ logged in (isolated) |
| Ekansh | `~/.orca-keys/Ekansh.env` | ✅ key set (shared Foundry key) | config dir set (login pending) |
| Dan | `~/.orca-keys/Dan.env` | ✅ key set (shared Foundry key) | config dir set (login pending) |
| Shaurya | `~/.orca-keys/Shaurya.env` | ✅ key set (shared Foundry key) | config dir set (login pending) |

## OpenCode key
All five profiles carry the same **Foundry (Fireworks-Azure) key** in `OPENCODE_FIREWORKS_API_KEY`,
so every `<Name>-opencode2` and every Orca-routed `opencode2` session authenticates. Each person
also has a matching `<Name>.opencode.json` (model config with cost tracking).
To give someone their own key/billing, replace just their `OPENCODE_FIREWORKS_API_KEY` value.

> Pitfall: a bare `opencode2` (no wrapper, no `.orca-owner` key) resolves
> `"apiKey": "{env:OPENCODE_FIREWORKS_API_KEY}"` to an **empty string** and Azure answers
> `401 Access denied due to invalid subscription key or wrong API endpoint`. Always launch via
> `<Name>-opencode2` or through Orca routing.

## GitHub identity
Each person can also have their **own GitHub account** for commits and PRs — see
`12-per-person-github-auth.md`. Authenticate once: `orca-gh-add <Name> <PAT>`.

## Claude subscription isolation
Claude Code keeps one login per `~/.claude`. To support multiple people we set
`CLAUDE_CONFIG_DIR` per person, so each has an independent account. Parth's login was
moved to `.orca-people/Parth/claude` (`.credentials.json` + `.claude.json`). Avi has an
empty config dir so he never inherits Parth's account.
