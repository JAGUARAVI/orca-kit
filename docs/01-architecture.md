# 01 — Architecture

```
Lightsail host (<tailscale-ip>, 8 vCPU / 30 GB)
  orca-serve.service       ── Orca runtime (worktrees, terminals, orchestration)
  worktrees/               ── one per feature (git worktree, isolated)
  orca-merge-agent.timer   ── automated merge agent (every 60s)
  agents: claude / codex / opencode2 / cursor-agent
        ▲
        │ Tailscale (private)
  teammates: Orca desktop + browser client + mobile

GitHub: <owner>/<repo>
  ci.yml  ── required status check
  main: protected (strict "checks"), auto-merge enabled
```

Flow: author agent → worktree → PR (label `merge-ready`) → merge agent lands it.
On conflict the merge agent resolves with an LLM; if the conflict is semantic it
escalates a question to the author agent, then applies the answer and merges.

There is **no separate merge queue** — the host merge agent is the single owner of
merge handling. `ci.yml` is the only GitHub Actions workflow.
