# SPEC: <Feature / product name>

Status: draft | review | accepted · Owner: <Name> · Updated: <date>

## 1. Problem & goal
<One paragraph in user terms. What pain are we removing?>

## 2. Non-goals (explicitly out of scope)
- <thing we will NOT do>
- <thing we will NOT do>

## 3. Users & user stories
- As a <role>, I want <capability> so that <benefit>.
- As a <role>, I want <capability> so that <benefit>.

## 4. Scope
**In:** <bullets>
**Out:** <bullets>

## 5. Interfaces & contracts (define first)
- Types / data model:
  ```
  <type / schema>
  ```
- API / function signatures:
  ```
  <signature>
  ```
- Events / file formats / env vars:
  - <...>

## 6. Behavior & edge cases
| Case | Expected behavior |
|---|---|
| empty input | ... |
| invalid input | ... |
| offline / error | ... |
| unauthorized | ... |

## 7. Constraints
- Compatibility: <...>
- Performance: <...>
- Security/privacy: <...>
- Allowed dependencies: <list> · New deps require an ADR.
- Do-not-touch paths: <paths>

## 8. Acceptance criteria (verifiable)
- [ ] `<command / test>` passes
- [ ] <observable behavior with exact inputs/outputs>
- [ ] <edge case handled with exact result>

## 9. Open questions
- [ ] <question> — owner: <Name> — decide by: <date>

## 10. Milestones (smallest releasable slices)
1. <slice> — acceptance: <...>
2. <slice> — acceptance: <...>
