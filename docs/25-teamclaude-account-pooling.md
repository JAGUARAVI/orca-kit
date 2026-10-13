# 25 — Pooling individual Claude/Codex accounts with TeamClaude

[TeamClaude](https://github.com/KarpelesLab/teamclaude) (`@karpeleslab/teamclaude`) is a **local
multi-account proxy** for Claude Code and the Codex CLI. It sits between the agent and the provider,
holds several accounts, and **rotates to the next account when the current one nears its session
(5h) or weekly (7d) quota** — so a long agent run keeps going instead of dying on a `429`.

This doc covers installing it on an Orca host and pooling accounts, so agents don't stall when one
subscription's quota runs out.

## ⚠️ Read this first (scope & terms)
TeamClaude's own words:

> **It is built for one person.** … Every account in the pool is **your own** … It is **not** a way
> to share an account between people.

So the honest model for an Orca team:
- **Each teammate signs in with their own account** (`teamclaude login`). The pool is a set of
  *distinct* individual accounts — not several people sharing one login.
- This is the supported shape: many accounts owned by the operators of the host, each under its own
  subscription/key and each person's own terms.
- **Do not** use it to let one group of people consume a single person's seats, and **not** as a
  hosted service for others. Read the official
  [compliance notes](https://github.com/KarpelesLab/teamclaude/blob/master/docs/compliance.md) and
  your provider's terms; this kit is not legal advice.
- TeamClaude is being renamed **TeamRouter** (the old name stays canonical for now; `teamrouter`
  runs the same CLI and every `TEAMCLAUDE_*` var is also read as `TEAMROUTER_*`).

If your goal is "a teammate should not have to stop because *their* quota is low", the right shape is
**pool several of the team's own accounts** on the shared host — which is exactly what follows.

## Install (Node 20+)
```bash
npm install -g @karpeleslab/teamclaude
teamclaude --version
```
No dependencies (Node built-ins only). A container image is on GHCR; see upstream docs.

## Add accounts
One command per account, run **once per account**:

```bash
teamclaude login                # browser OAuth, the same flow as Claude Code
teamclaude login --api          # an Anthropic API key (metered; added at low priority)
teamclaude login --codex        # a ChatGPT/Codex subscription account (experimental)
teamclaude import               # reuse an existing Claude Code login (no fresh OAuth)
```

On a headless Orca host (no `DISPLAY`, over SSH) no browser opens: `login` prints a URL you open on
your laptop and a code you paste back. For Codex over SSH, forward the callback port:
`ssh -t -L 1455:localhost:1455 <host>`.

**Per person, from their own account:** each teammate runs `teamclaude login` on the host and signs
in as themselves (or signs in on their laptop and syncs — see *callback.net*). The pool then holds
everyone's individual accounts and rotates across them.

As an Orca host convenience, wrap the login in the person's isolated profile so the sign-in and the
config it lands in are theirs (matches the kit's per-person model, doc 05):
```bash
. ~/orca-kit/lib/orca-kit.sh
GH_CONFIG_DIR="$PEOPLE_DIR/<Name>/gh" teamclaude login --name "<Name>@laptop"   # example
```

## Configure
Config: `~/.config/teamclaude.json` (hand-editable; `$XDG_CONFIG_HOME` honoured). A proxy API key is
generated on first use. Quota is tracked in `teamclaude.state.json` beside it (safe to delete).

Key knobs (see upstream `docs/configuration.md` for all):
- `priority` — rotation order, **lower = preferred**. API keys default to `100` (fallback tier).
- `disabled` — pause an account without removing it.
- `upstream` + `modelMap` — treat any **Anthropic-compatible** backend (DeepSeek, GLM, or this kit's
  Fireworks/Foundry deployment) as a low-priority account.
- `autoRedeemResets` — opt-in; spend a banked Claude/Codex reset grant when the whole pool is dry.

Route a **third-party backend** (e.g. the kit's `fireworks-azure` deployment) as a fallback:
```json
{ "name": "foundry", "type": "oauth", "accessToken": "sk-…",
  "upstream": "https://<your-foundry>.services.ai.azure.com/openai/v1",
  "priority": 100 }
```

## Run it, and point the agents at it
```bash
teamclaude server                 # start the proxy (TUI with quota bars, resets, activity)
teamclaude status                 # proxy status (needs the server up)
teamclaude run                    # run Claude Code *through* the proxy, in another terminal
teamclaude alias --install        # make plain `claude` go through the proxy
```
For Orca agents, point the agent at the proxy instead of the provider:
- **Claude Code:** `ANTHROPIC_BASE_URL=http://127.0.0.1:<port>` (or the `teamclaude run` wrapper /
  the installed alias) in the person's env file (`$KEYS_DIR/<Name>.env`).
- **Codex:** set `~/.codex/config.toml` `model_provider = "teamclaude"` with
  `base_url = "http://127.0.0.1:<port>/backend-api/codex"`, or use MITM mode
  (`eval "$(teamclaude env)"` → `HTTPS_PROXY` + `NODE_EXTRA_CA_CERTS`).

Because agents already launch through the kit's `orca-route`, adding the base-url to the per-person
env makes **routing + pooling compose**: the agent uses that person's identity, and the proxy pools
the accounts behind it.

Run the proxy as a service so it survives reboots (adapt the kit's systemd pattern):
```ini
# ~/.config/systemd/user/teamclaude.service
[Unit]
Description=TeamClaude proxy
[Service]
ExecStart=%h/.local/bin/teamclaude server
Restart=always
[Install]
WantedBy=default.target
```

## Operate
```bash
teamclaude accounts               # accounts, tier, token status
teamclaude disable <name>         # pause an account (e.g. one person's, out of office)
teamclaude priority <name> 1      # make an account preferred
teamclaude status --json          # machine-readable; carries callbackSync + per-account errorReason
```
Quota policy worth knowing: it rotates at **98%** of a bucket (both 5h and 7d), prefers the account
whose week resets soonest, distinguishes a **spent bucket** from a **per-minute 429** (paces instead
of rotating), and can **hold the request open until quota resets** rather than returning 429
(`holdSeconds`, off by default) — useful for unattended Orca runs.

## Syncing tokens across machines (callback.net)
If several Orca hosts (or a laptop + host) hold the same accounts, sign each install in to
[callback.net](https://www.callback.net/) so they keep each other's OAuth tokens fresh instead of
each needing a re-login every few days:
```bash
teamclaude callback login         # prints a URL to approve in any browser
teamclaude callback status
teamclaude callback sync
```
Upstream is explicit that callback.net stores *your own* tokens for syncing **your own** machines —
**"it is not a place to share accounts with other people."** Pool the accounts on the host; sync
tokens only between the machines you run.

## How it fits the kit
| Kit piece | Interaction |
|---|---|
| per-person env (`$KEYS_DIR/<Name>.env`) | add `ANTHROPIC_BASE_URL`/Codex provider to route an agent through the pool |
| `orca-route` | routes the **identity**; TeamClaude pools the **accounts** behind it — they compose |
| `04-opencode-foundry.md` | the Foundry deployment can be a `upstream`/`modelMap` fallback account |
| `07-security.md` | tokens live under `~/.config/teamclaude.json` (0600) and `…callback.json`; treat like keys |
| CI / agents | run the proxy as a service; unattended runs benefit from `holdSeconds` |

## Security
- Tokens sit in `~/.config/teamclaude.json` and `~/.config/teamclaude.callback.json` — **0600**,
  same handling as `$KEYS_DIR` (doc 07). Back up the config; never commit it.
- The upstream project warns the only canonical sources are the GitHub repo and the npm package —
  **never** a downloadable zip binary.
- One account's traffic can be sent through its **own HTTP/SOCKS proxy** (`teamclaude routing`) —
  useful if an account's provider expects a particular egress region.

## Verify
```bash
npm ls -g @karpeleslab/teamclaude
teamclaude accounts
teamclaude status --json | jq '.accounts[] | {name, tier, disabled, errorReason}'
# pooled end-to-end:
ANTHROPIC_BASE_URL=http://127.0.0.1:<port> claude -p "say PONG"
```

## Notes / pitfalls
- **Dedup is per account+org** — one email in several orgs becomes `email (Org)`; disambiguate with
  `teamclaude remove <email> --org <org>`. A duplicated account block gets a fresh `id` on next read.
- **Renaming** an account while the server runs is fine; a rename with the server **stopped** loses
  an API-key account's saved quota readings (they're matched by name).
- **A 401 on an API key** fails over and benches the account for a growing cooldown (1m → 5m → 15m →
  1h), not permanently — a gateway hiccup recovers by itself.
- **Claude Code's own identity calls** are not proxied through the pool (they use the client login),
  so a routed account does not change who you're "signed in as" for those.
- If the whole pool is spent and `holdSeconds` is off, agents get a 429 — surface it and let the
  merge/agent loop retry, or enable holding for unattended runs.
- **Terms:** the multi-subscription question is addressed in upstream `docs/compliance.md`.
  Confirm it fits your team's provider agreements before pooling.