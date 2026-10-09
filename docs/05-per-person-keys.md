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
| Avi | `~/.orca-keys/Avi.env` | ✅ (his key) | config dir set (login pending) |
| Parth | `~/.orca-keys/Parth.env` | blank | ✅ logged in (isolated) |
| Ekansh | `~/.orca-keys/Ekansh.env` | blank | config dir set (login pending) |
| Dan | `~/.orca-keys/Dan.env` | blank | config dir set (login pending) |
| Shaurya | `~/.orca-keys/Shaurya.env` | blank | config dir set (login pending) |

## Claude subscription isolation
Claude Code keeps one login per `~/.claude`. To support multiple people we set
`CLAUDE_CONFIG_DIR` per person, so each has an independent account. Parth's login was
moved to `.orca-people/Parth/claude` (`.credentials.json` + `.claude.json`). Avi has an
empty config dir so he never inherits Parth's account.
