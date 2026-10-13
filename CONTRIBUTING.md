# Contributing to the Orca Hackathon Kit

Thanks for helping. This kit is the orchestration layer for running many coding agents on one
codebase — so the bar is: **changes must be safe for a repo whose `main` is being written by several
agents at once.**

## Ways to contribute

| Kind | Start here |
|---|---|
| 🐛 Bug in a script | Open an issue with the command, expected vs actual, and `bash -x` output |
| 📄 Docs / typo | A PR against the file directly |
| 🧩 New agent support | `docs/27-adding-agents.md`, then a `person/orca-route-<agent>` wrapper |
| 🤖 New skill | `skills/_template/SKILL.md`, then a row in `skills/README.md` |
| ⚙️ Automation / workflow | `docs/22-efficiency-automations.md` — include the measured problem it fixes |
| 🔁 New repo blueprint | `docs/11-porting-to-a-new-repo.md` |

## Ground rules

- **No hardcoded paths.** Everything machine-specific goes in **one** env file
  (`orca-kit.env.example` → `~/.orca-kit.env`) and is read through `lib/orca-kit.sh`. A script that
  hardcodes `$HOME`, a repo slug, or an owner name will be asked to change. Use the placeholders
  `<owner>`, `<owner/repo>`, `<Name>`, `<PHASE>`, `<ID>`, `<repo-dir>`.
- **No secrets, ever.** Not in code, not in docs, not in tests, not in commit history. Access links
  and pairing tokens are passwords — never commit them.
- **Idempotent scripts.** Setup, issue creation, and sync commands must be safe to re-run.
- **Explain the *why*.** Every automation should name the measured problem it fixes (see
  `docs/26-case-study.md` for the model). "It's cleaner" is not enough.
- **Keep the spine.** The contract is one task = one worktree = one agent = one PR; don't merge your
  own PR; honour owned paths. Changes that weaken these need a strong, written reason.

## Development setup

```bash
git clone https://github.com/JAGUARAVI/orca-kit.git ~/orca-kit && cd ~/orca-kit
cp orca-kit.env.example ~/.orca-kit.env     # edit KIT_OWNER / MODEL / GH as needed
find . -name '*.sh' -o -name 'orca-*' | xargs -I{} bash -n {}   # syntax check everything
```

There is no build. Validate before you push:

```bash
# shell syntax
for f in $(find . -type f -name '*.sh'; echo bin/*); do bash -n "$f" || echo "FAIL $f"; done
# python syntax
for f in github/*.py; do python3 -m py_compile "$f" || echo "FAIL $f"; done
# yaml
python3 - <<'PY'
import yaml,glob
for f in glob.glob('github/*.yml')+glob.glob('github/issue-templates/*.yml'):
    yaml.safe_load(open(f))
print("yaml ok")
PY
# no stray secrets / hardcoded paths
grep -rniE 'gho_|ghp_|sk-[A-Za-z0-9]{20,}|pair%3Fcode|/home/[a-z]+/' --include='*' . | grep -v '.git/'
```

## PR process (dogfooding the kit)

This repo runs on the very workflow the kit ships:

1. **Branch** `feat/<slug>` or `fix/<slug>` off `main`.
2. **Keep the change scoped** — one concern. Update the relevant doc (`docs/00-index.md` lists them)
   and any template or README table that names the file you touched.
3. **Run the validation block above.**
4. Open a PR, describe **what problem it fixes** and how you verified it, and link any issue.
5. Label it **`merge-ready`** — do not merge your own PR; the merge agent lands it.
6. If it changes a plan/README/`AGENTS.md`, say why in the description so reviewers can check the
   agent-facing contract still holds.

> Working *with* the kit as an agent? Read **`AGENTS.md`** first — it is the agent's instruction file
> for this repo.

## Style

- Docs: short, concrete headings; tables over prose; a diagram where it clarifies. Every command in a
  doc should be copy-pasteable (use `<placeholders>` for the specifics).
- Scripts: `set -uo pipefail`, source `lib/orca-kit.sh`, no hardcoded paths, clear `usage`/`--help`.
- Commit messages: `feat|fix|docs|chore(scope): summary`.

## License

By contributing you agree your work is licensed under the repo's **MIT License** (see `LICENSE`).