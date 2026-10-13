# 21 — Run CI on the VM (self-hosted Actions runner)

**Why:** GitHub-hosted Actions minutes for a **private org repo** are billed to the org
(`<org>`). When the org's spending limit is hit, jobs don't fail on code — they never
start, with the annotation:

> *"The job was not started because recent account payments have failed or your spending
> limit needs to be increased."*

A self-hosted runner is **not** billed as GitHub-hosted minutes, so this bypasses the limit.
Switching the local `gh` token (`<OwnerA>-gh` → `<OwnerB>-gh`) does **not** help: CI uses the repo's
automatic `GITHUB_TOKEN` on GitHub-hosted runners; the local token is irrelevant.

## What was installed
- Runner `actions/runner` (latest) at `$RUNNER_DIR` (default `~/actions-runner`).
  One command: `systemd/orca-runner-bootstrap.sh <owner/repo>`.
- Registered at **repo level** for `<owner/repo>`:
  name `orca-vm-<hostname>`, labels **`self-hosted, linux, x64, orca-vm`**.
- systemd service: `actions.runner.<owner>-<repo>.<runner-name>.service`
  (enabled, active; starts on boot). Managed via `~/actions-runner/svc.sh`.
- Host prerequisites installed: `libnss3 libnspr4 libdbus-1-3 libatk1.0 libatk-bridge2.0
  libatspi2.0 libxcomposite1 libxdamage1 libxfixes3 libxrandr2 libgbm1 libxkbcommon0
  libpango-1.0 libcairo2 libasound2 libcups2 fonts-liberation` (Playwright/Lighthouse).
- `pnpm 12.10.1` and `node 22` already on PATH. Playwright chromium already cached.

## Workflows now target it
`runs-on: [self-hosted, linux, x64, orca-vm]` in:
- `.github/workflows/ci.yml`
- `.github/workflows/e2e.yml`
- `.github/workflows/task-reconcile.yml`

Note: labels are matched **case-insensitively** (`Linux`≡`linux`, `X64`≡`x64`).

## Verify
```bash
gh api repos/<owner/repo>/actions/runners \
  --jq '.runners[]|"\(.name) \(.status) busy=\(.busy) \(.labels|map(.name)|join(","))"'
# -> orca-vm-... online busy=false self-hosted,Linux,X64,orca-vm

sudo ~/actions-runner/svc.sh status
tail -f ~/actions-runner/_diag/Worker_*.log
```

## Operate
```bash
cd ~/actions-runner
sudo ./svc.sh stop     # pause
sudo ./svc.sh start    # resume
sudo ./svc.sh uninstall
# re-register (after a token expires):
TOKEN=$(gh api -X POST repos/<owner>/<repo>/actions/runners/registration-token --jq .token)
./config.sh --url https://github.com/<owner>/<repo> --token "$TOKEN" \
  --name "orca-vm-$(hostname)" --labels "self-hosted,linux,x64,orca-vm" --unattended --replace
```

## Cautions
- **One runner = jobs are serialized.** `ci` and `e2e` on the same PR run one after the other.
  Run a second `config.sh` into `~/actions-runner-2` for parallelism.
- The runner executes **untrusted PR code** on the VM (same box as the agents/keys). For a
  private team repo this is acceptable; if the repo ever goes public, gate with environments
  or use an isolated runner host.
- Keep it on a **custom label** (`orca-vm`) rather than bare `self-hosted` so public/fork PRs
  can't target the VM accidentally.
- Billing fix is still worth doing on the org side; the runner just unblocks CI meanwhile.

## Pitfall: stale dev servers on the shared runner (port collisions)
The runner shares the VM with agents running `vite`/`vite preview`. An agent's dev server
left listening on a port the CI job needs makes jobs fail *even though the code is fine*:

```
Error: http://127.0.0.1:4173 is already used, make sure that nothing is running on the
port/url or set reuseExistingServer:true in config.webServer.
```

This cannot happen on a GitHub-hosted runner (fresh VM each job) but **is** a real risk here.
Observed: an orphaned `vite preview --port 4173` from `~/orca/workspaces/.../p0-20-app-integration`
(reparented to PID 1 after its launcher exited) blocked the E2E job.

**Fix applied (in the repo, commit `8c10544`):**
- `e2e.yml` gains a **"Free E2E port"** step before anything else: `fuser -k -n tcp 4173 4174`
  (falls back to `ss`+`kill`), then asserts the ports are free and fails loudly if not.
- `playwright.config.ts`: in CI the webServer binds a dedicated port with `--strictPort`
  (via `E2E_PORT`, default 4173) so it fails fast instead of silently reusing a foreign server;
  `reuseExistingServer` stays `false` in CI. Local runs are unchanged.

**General rule for this runner:** any job that binds a fixed port must free it first, because
the machine is never clean. Alternatively isolate jobs with `E2E_PORT=<unique>` per job.

**Manual cleanup of orphans:**
```bash
sudo ss -ltnp | grep -E ':4173|:5173|:4317'   # find squatters
sudo fuser -k -n tcp 4173                      # free a port
```
