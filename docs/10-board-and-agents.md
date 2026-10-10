# 10 — Task / decision board

The board is the shared control surface for **features and decisions** (the Orca runtime gives
shared execution; the board gives shared intent).

## This project
- **Megathon GS Vanguard — Task Board** — https://github.com/users/<owner>/projects/<n>
- Repo: `<owner>/<repo>`
- Fields: **Status** (Todo / In Progress / Done), **Owner**, **Worktree**.
- Cards: the P0 slice, spec/interfaces work, and the open decisions.

## Other boards
- **Orca Demo — Feature Board** — https://github.com/users/<owner>/projects/<n> (demo repo).

## Why it lives under `<owner>`, not the org
- Org project creation is disabled for this account (`viewerCanCreateProjects: false`).
- A **user** project cannot link an **org-owned** repo (GitHub requires the same owner), so the
  Repository column stays empty. If IIIT-ECell enables org projects, move/relink it.

## Using it
1. Card per feature/decision; set **Owner**.
2. Create a worktree; paste its name into **Worktree**; move to *In Progress*.
3. Link the PR (`worktree set --pr <n>`), label it `merge-ready`.
4. Move to *Done* on merge.
5. Decisions: one card per decision, referencing its ADR (`docs/adr/…`).

## Creating a board for another repo
```bash
/home/ubuntu/orca-kit/github/setup-board.sh <owner> "<Title>" [<owner/repo>]
```
Creates the project, adds the **Owner** field; add **Worktree** with
`gh project field-create <n> --owner <owner> --name Worktree --data-type TEXT`.
(Project creation requires the GraphQL `project` scope on the token.)
