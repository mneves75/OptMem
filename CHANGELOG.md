# Changelog

All notable changes to this fork. The store format (`LOG.txt`, `TREE/`,
`config`) is unchanged, so every version reads every store.

## 1.2.0 — 2026-09-15

### Security

- `note` and `nap` accept `-` to read their line from stdin, and every order
  memo prints (the nap prompt, the setup block, usage, the empty-wake hint)
  hands the line over through a quoted heredoc: `memo nap 4-5 - <<'MEMO'`.
  The old orders put `"<your line>"` in double quotes, and memories quote
  commands: a summary retyped from a memory holding `` `cmd` `` or `$(cmd)`
  ran it in the agent's shell (reproduced), and `$VAR` silently vanished.
  The heredoc is the one form on every platform: a PowerShell here-string is
  an ordinary quoted word to Git Bash, which the first apostrophe ends.
  Arguments work as before.
- Stdin past what a memory can be is refused, never cut short, and a leading
  byte-order mark is dropped.
- The tool's own path is printed with `/` separators and shell-quoted in
  every order when it holds a space or another character a shell would split
  or expand, keeping a leading `~/` bare so it still expands.
- WINDOWS.md states what the umask does not do on NTFS, how to restrict a
  store from PowerShell, and how to note from PowerShell without a heredoc.

## 1.1.0 — 2026-09-15

### Added

- `WAKE_BYTES` caps the bytes `wake` prints (0, the default, is no cap). It
  prints the finest memory of at most `WAKE_LINES` lines that fits the cap in
  one part. A summary nobody has compressed yet stands in as its two halves,
  down to the raw memories, so sessions that note and never nap cost the wake
  some bytes instead of the whole past; those raw lines may take it past
  `WAKE_LINES`, since the cap is bytes. A pending compression that does not
  fit next to the memory is replaced by one line:
  `N compressions pending. Run: memo nap`. This is for startup hooks, which
  are cut in place: Claude Code keeps 10,000 characters of a hook and shows
  the agent a 2 KB preview of anything longer. Supersedes upstream PR #7.
  - If even the smallest document would arrive in parts, or so much is
    uncompressed that nothing could fit, wake hands over the pending
    compression instead.
  - The walk down from `WAKE_LINES` starts at the number of memories, so a
    huge `WAKE_LINES` costs nothing.
- The usage text shows the version.

### Security

- `note`, `nap` and `import` share one write guard, which now refuses:
  - every line break `str.splitlines()` knows, not just `\n` and `\r`. A
    memory holding one was stored as one line and printed as two, so it could
    forge a `#a-b` summary line or the `You are awake.` terminator (upstream
    #12; PRs #13 by @codeAnqiang-ma and #15 by @sjwauto123);
  - C0 and C1 control characters other than tab, such as terminal escapes;
  - invisible Unicode format characters (category Cf, except the zero-width
    joiners emoji and some scripts need): bidi overrides that reorder what a
    person reads, zero-width spaces, and tag characters that spell text no
    terminal shows;
  - strings shaped like credentials (OpenAI and Anthropic keys, GitHub, AWS,
    Slack, Google, Stripe, GitLab, Hugging Face and npm tokens, JWTs,
    private-key headers). The log is append-only, so a secret noted once used
    to reach every future wake.
- Stored text is printed with control characters, invisible format
  characters and line separators replaced by U+FFFD. Nothing this version
  writes contains them; this covers a record written by another writer, such
  as an older memo on a synced store, which could otherwise forge a line.
- Everything `memo` creates is readable by its owner only (umask 077) on
  macOS and Linux. Existing stores keep their modes; run
  `chmod -R go-rwx ~/.optmem` once. Windows ACLs are not set: see WINDOWS.md.

### Fixed

- A summary record torn by a crash is treated as not built. `wake` offers the
  nap that rebuilds it instead of printing the fragment as memory, and no
  longer points at a `forget` that cannot drop it (upstream #10; PR #11 by
  @codeAnqiang-ma).
- A corrupt memory record in `LOG.txt` is reported by memory id with exit
  code 1 instead of a Python traceback.
- A blank summary record points straight at `forget`, even while other
  compressions are pending.
- No input reaches a Python traceback any more: non-ASCII or oversized
  numbers, a config file that is not UTF-8, argument bytes that are not UTF-8,
  and a `nap` block id past the end of the memory are all reported in the
  tool's own words.
- `import` accepts only ASCII dates, so a date written in other digits can no
  longer break the date order or leave a partial import behind, and a refused
  line is echoed without its control characters.
- `recall` reads the records that existed when it started, so a note landing
  mid-search cannot misalign it.
- On Windows, the lock wait counts the time it actually slept, so the 30 s
  limit is 30 s.

## 1.0.0 — upstream `1fb164c` (2026-07-31)

Baseline: [VictorTaelin/OptMem](https://github.com/VictorTaelin/OptMem) at
commit `1fb164c`, which had no version number.
