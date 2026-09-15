# Changelog

All notable changes to this fork. The store format (`LOG.txt`, `TREE/`,
`config`) is unchanged, so every version reads every store.

## 1.1.0 — 2026-09-15

### Added

- `WAKE_BYTES` caps the bytes `wake` prints (0, the default, is no cap). It
  prints the finest memory of at most `WAKE_LINES` lines that fits, and it
  only picks covers whose summaries are already built, so a byte cap never
  turns a wake into a refusal. A pending compression that does not fit next
  to the memory is replaced by one line: `N compressions pending. Run: memo nap`.
  This is for startup hooks, which are cut in place: Claude Code keeps 10,000
  characters of a hook and shows the agent a 2 KB preview of anything longer.
  Supersedes upstream PR #7.
- The usage text shows the version.

### Security

- `note`, `nap` and `import` share one write guard, which now refuses:
  - every line break `str.splitlines()` knows, not just `\n` and `\r`. A
    memory holding one was stored as one line and printed as two, so it could
    forge a `#a-b` summary line or the `You are awake.` terminator (upstream
    #12; PRs #13 by @codeAnqiang-ma and #15 by @sjwauto123);
  - C0 and C1 control characters other than tab, such as terminal escapes;
  - strings shaped like credentials (OpenAI and Anthropic keys, GitHub, AWS,
    Slack, Google, Stripe and GitLab tokens, JWTs, private-key headers). The log
    is append-only, so a secret noted once used to reach every future wake.
- Everything `memo` creates is readable by its owner only (umask 077). Existing
  stores keep their modes; run `chmod -R go-rwx ~/.optmem` once.

### Fixed

- A summary record torn by a crash is treated as not built. `wake` offers the
  nap that rebuilds it instead of printing the fragment as memory, and no
  longer points at a `forget` that cannot drop it (upstream #10; PR #11 by
  @codeAnqiang-ma).
- A corrupt memory record in `LOG.txt` is reported by memory id with exit
  code 1 instead of a Python traceback.
- A blank summary record points straight at `forget`, even while other
  compressions are pending.

## 1.0.0 — upstream `1fb164c` (2026-07-31)

Baseline: [VictorTaelin/OptMem](https://github.com/VictorTaelin/OptMem) at
commit `1fb164c`, which had no version number.
