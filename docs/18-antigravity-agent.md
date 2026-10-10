# 18 — Google Antigravity CLI (`agy`) as an agent

Antigravity is Google's agentic CLI. Binary: **`agy`** (installed to `~/.local/bin/agy`).
Config lives under **`~/.gemini/antigravity-cli/`** (`settings.json`, credentials cache,
hooks, skills, plugins).

## Why an isolated HOME (not just a config dir)
Antigravity reads its profile from `$HOME/.gemini/…` and stores credentials in the OS
keyring/cache under that profile. The **official Google method for per-worker isolation is an
isolated `HOME`** (their documentation, "Supported controls …" and the install docs). So each
person gets their own Antigravity HOME; the CLI then behaves as a separate signed-in user.

Per person:
```
~/.orca-people/<Name>/antigravity/.gemini/antigravity-cli/   # 700: settings + credentials
~/.local/bin/<Name>-antigravity                              # wrapper (isolated HOME)
~/.local/bin/<Name>-antigravity-login                        # interactive sign-in helper
```

## Wrapper behaviour
`<Name>-antigravity` sources the person's env (so `GH_CONFIG_DIR`/`GIT_*` still apply), sets
`HOME` to the isolated profile, and execs `agy`. Example (`Ekansh-antigravity`):
```bash
export HOME=/home/ubuntu/.orca-people/<Name>/antigravity
exec /home/ubuntu/.local/bin/agy "$@"
```

## Sign in (once, per person)
```bash
<Name>-antigravity-login        # interactive: complete Google sign-in
# or headless/SSH: <Name>-antigravity   then follow the printed URL on your own machine
```
`agy models` fails with *"Please sign in"* until this is done.

## Using it
```bash
<Name>-antigravity                     # interactive TUI
<Name>-antigravity -p "explain this diff"        # one-shot, non-interactive
<Name>-antigravity --model <slug> -p "…"
<Name>-antigravity --effort high -p "…"
<Name>-antigravity agents / models     # list agents / models
```
**Headless note:** in non-interactive runs (`-p`), shell/write tools default to *ask* and are
soft-denied unless allowed. Pre-approve in the isolated profile's `settings.json`:
```json
{ "permissions": { "allow": ["command(git)", "command(regex:npm run (build|lint|test))", "write_file(src/)"] } }
```
Or pass `--dangerously-skip-permissions` (only for trusted, bounded work).

## Orca integration
Orca's `--agent` flag accepts **known TUI agent ids** (claude, codex, opencode2, cursor, …).
`agy` is not in the bundled list, so launch it as a custom command:
```bash
orca-ide terminal create --worktree active --title antigravity --command "/home/ubuntu/.local/bin/<Name>-antigravity" --json
# or, in a new worktree:
orca-ide worktree create --name feat-x --no-parent --json
orca-ide terminal wait --terminal <handle> --for tui-idle --timeout-ms 60000 --json
orca-ide terminal send --terminal <handle> --text "<task brief>" --enter --json
```
Routing: with `.orca-owner` = `<Name>` and a per-name wrapper, the correct profile is used.

## Status
| Person | binary | wrapper | profile HOME | signed in |
|---|---|---|---|---|
| Ekansh | ✅ agy 1.3.3 | ✅ | `.orca-people/Ekansh/antigravity` | ⏳ run `Ekansh-antigravity-login` |
| others | (installed system-wide) | add via `orca-keys-add` or copy the wrapper | — | — |

## Notes
- Auto-update: set `AGY_CLI_DISABLE_AUTO_UPDATE=true` to stop background self-updates.
- Antigravity uses the Google account's quota; it does **not** use the Fireworks/Foundry key.
- `GEMINI_API_KEY` (with `modelProvider:"gemini"`) is an alternative for headless/CI, but the
  team uses Google OAuth with one isolated profile per person.
