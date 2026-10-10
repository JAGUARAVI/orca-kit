# Task brief: <title>            ← ONE task; one card = one worktree = one agent = one PR

Repo: <owner/repo> · Base: origin/main · Owner: <Name> · Card: P0-04 · Depends on: P0-01 · Gate: <optional>

## Target
<the exact files/component in scope — list paths>

## Change
<the concrete result: what to build, the APIs/signatures, the behaviour>
- <bullet the pieces>
- <note any frozen interface this must obey>

## Constraints
- Read and follow: AGENTS.md, SPEC.md, docs/adr/
- Do-not-touch: <paths another task owns>
- Allowed dependencies: <exact list> (new ones need an ADR)
- Non-goals: <what NOT to do>

## Ownership
- You may edit: `<paths>`
- Do not edit: anything else

## Observable acceptance
- [ ] `<exact command>` passes
- [ ] <observable behaviour: exact inputs → outputs>
- [ ] <edge case → exact result>

## Definition of Done
- [ ] acceptance passes · [ ] tests added · [ ] docs/ADR updated · [ ] comment+status updated · [ ] PR small
