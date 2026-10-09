# Orca setup — short summary

We run a **shared Orca runtime on a cloud host**. You connect over **Tailscale** with an Orca client
and drive coding agents (**Claude Code, Codex, OpenCode v2, Cursor**) in parallel — each task in its own
**git worktree**, so agents working on the same file don't collide. Work lands via **PRs**, and an
**automated merge agent** merges ready PRs, resolves safe conflicts, and asks the author agent when a
conflict is semantic. A shared **GitHub Project board** tracks features and decisions.

**You do:**
1. Join Tailscale, connect Orca with the access link.
2. `echo <YourName> > .orca-owner`, then use `<YourName>-opencode2` / `<YourName>-claude`.
3. Push a branch → open a PR → label it `merge-ready`.
4. Track your card on the board.

**Links:** repo `<owner>/<repo>` · board https://github.com/users/<owner>/projects/1
· detailed guide `~/orca-welcome/WELCOME.md` · docs `~/orca-docs/00-index.md`.
