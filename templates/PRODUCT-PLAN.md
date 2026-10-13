# Product plan — <Product name>

> The **product plan** is the mid-point between a raw idea and a technical plan. It is written in
> product language (problems, users, outcomes, scope), **not** in code. It is the artefact the
> technical plan implements and the task DAG delivers. Keep it to a read-once length; link out for
> detail. Delete the guidance lines as you fill it in.

## 1. One-line summary
<What this is, for whom, in one sentence.>

## 2. Problem & why now
- **Problem:** <the user/business problem, with evidence if you have it.>
- **Why now:** <deadline, opportunity, dependency, cost of not doing it.>
- **Success signal:** <the observable change that means this worked.>

## 3. Users & jobs
| User | Job to be done | Today's pain | What "better" looks like |
|---|---|---|---|
| <persona> | <job> | <pain> | <outcome> |

## 4. Goals / non-goals
- **Goals:** <the few outcomes this must achieve — measurable.>
- **Non-goals:** <what is explicitly out of scope for this version, and why.>

## 5. Scope by phase
Keep phases small and shippable. Each phase ends at a **gate** a person signs off.

| Phase | Theme | In scope | Out of scope | Gate (exit criteria) |
|---|---|---|---|---|
| P0 | <playable slice / smallest useful version> | <…> | <…> | <what proves P0 is done> |
| P1 | <…> | | | |
| P2 | <…> | | | |

## 6. Experience & flow
<The user journey in plain language, and the key screens/states. A short diagram is welcome.
This is what the technical plan will turn into components.>

## 7. Requirements (product-level)
Prioritised, verifiable, technology-free. These become acceptance criteria later.
| ID | Requirement | Priority | How we'll know (observable) |
|---|---|---|---|
| FR-1 | <…> | must | <observable check> |
| FR-2 | <…> | should | |
| NFR-1 | <perf / a11y / privacy / offline…> | must | <threshold> |

## 8. Constraints & dependencies
- **Constraints:** <time, budget, platform, policy, team size.>
- **Dependencies:** <external services, data, approvals, other teams.>
- **Assumptions (must be validated):** <…>

## 9. Risks
| Risk | Likelihood | Impact | Mitigation / early signal |
|---|---|---|---|

## 10. Milestones & dates
| Milestone | Date | Deliverable | Owner |
|---|---|---|---|

## 11. Open questions (human gates)
<Decisions a named person must make before certain work starts. These become `⛩` gates in the
task DAG.>
- [ ] <question> — <decider>

## 12. Handoff to the technical plan
<Link the follow-up artefacts once they exist:>
- Technical plan: `docs/technical-implementation-plan.md`
- Spec: `SPEC.md`
- Task index: `docs/tasks/README.md`