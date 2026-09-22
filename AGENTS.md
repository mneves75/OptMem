# OptMem

One Python 3 file, `memo`, with no dependencies beyond the standard library.
`test.py` is the whole test suite: run `python3 test.py` and expect
`N passed, 0 failed`. Its timing checks (`find` under 0.1 s, a capped wake
under 2 s) measure wall clock, so a saturated machine can fail them; compare
against the previous release on the same machine before blaming a change.

- Every order `memo` prints must run as printed: it starts with the tool's
  own path, hands text over through a quoted heredoc, and quotes anything a
  user typed.
- Every error goes through `die()`, and every echoed argument, path or
  stored text through `clean()`. No input may reach a Python traceback.
- A bug fix starts with a test in `test.py` that fails without it.
- A release bumps `VERSION` in `memo`, adds a `CHANGELOG.md` entry in its
  existing style, and lists the sha256 of `memo` in the release notes, for
  `OPTMEM_SHA256` in a pinned install.

## Agent skills

### Issue tracker

Issues live in this repository's GitHub Issues, used through the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

The five default labels: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `CONTEXT.md` and `docs/adr/` at the repository root, created when first needed. See `docs/agents/domain.md`.
