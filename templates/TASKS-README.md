# Task breakdown — <project>

Source: `<plan doc>`. Each task is **one card = one worktree = one agent = one PR**
(see `docs/orca-kit/15-work-division-and-delegation.md`). Every brief in `P0/`, `P1/`, …
follows `templates/TASK-BRIEF.md` and can be pasted as the `--prompt` of `orca-ide worktree create`.

## Rules that make the parallel split safe
1. **Interfaces first.** One early task lands all shared types/schemas; after it merges the
   contracts are frozen for the wave (changes need their own small PR).
2. **Dependencies frozen.** One early task installs all deps and writes the ADRs; no other task
   edits `package.json`/lockfile.
3. **Disjoint ownership.** No two concurrently-runnable tasks own the same path. The "Owns" column
   is the full list of paths a task may edit.
4. **Registries have one writer.** Shared registries (e.g. `index.ts`) are created empty early and
   filled by exactly one task per phase.
5. **Per-task files.** Each feature owns its own folder/namespace so no two tasks edit one file.
6. **Human gates** are marked ⛩ and block downstream tasks until the named person signs off in the PR.

## <PHASE> — <goal>

```mermaid
flowchart LR
  T01["<ID> <name>"] --> T04["<ID> <name>"]
  T04 --> T05["<ID> <name>"]
```

| ID | Task | Depends on | Owns (may edit) | Agent fit |
| --- | --- | --- | --- | --- |
| [P0-01](P0/P0-01-slug.md) | <name> | — | `<paths>` | Strong reasoning |
| [P0-04](P0/P0-04-slug.md) | <name> | P0-01 | `<paths>` | Fast |

### Orca runs
| Run | Tasks | Max parallel agents |
| --- | --- | --- |
| 1 | P0-01, P0-02, P0-03 | 3 |
| 2 | P0-04 (P0-03 continues) | 2 |

> Then generate the GitHub issues with
> `orca-kit/github/create-task-issues.py --repo <owner/repo> --deps docs/tasks/deps.json`.
