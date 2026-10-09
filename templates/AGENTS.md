# AGENTS.md — rules for agents in this repo

## Read first
SPEC.md · docs/adr/ · CONTRIBUTING.md · your task brief.

## Scope
Do only what the task brief names. No opportunistic refactors. Honor non-goals and do-not-touch paths.
No new dependency without an ADR. If ambiguous or conflicting with the spec, STOP and ask.

## Commits & branches
`feat|fix|chore|docs(scope): message`. Branch `feat/<slug>`. Never force-push shared branches.
Never commit secrets. Small PRs (< ~400 lines).

## Definition of Done (before labeling `merge-ready`)
acceptance criteria pass · tests added · docs/ADR updated · linters/CI green · comment+status updated ·
scope matches brief · no frozen paths touched.

## Ask vs proceed
Ask when the spec is silent/conflicting, a new dep is needed, a public interface would change, or a
frozen path is involved.

## Merge & authorship
Add `Co-authored-by:` when integrating someone else's work. Don't merge your own PR; label `merge-ready`.
