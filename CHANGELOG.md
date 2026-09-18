# Changelog

All notable changes to this fork. The store format (`LOG.txt`, `TREE/`,
`config`) is unchanged, so every version reads every store; the one
exception is a `config` that sets a size an older version does not know
(see 1.3.0).

## 1.3.0 — 2026-09-18

### Added

- `find <words...> [--top N]` ranks every memory and every built summary by
  BM25 (k1=1.2, b=0.75) over their words, ignoring case and accents and
  indexing each word both as written and as a stem (a plural `s` dropped,
  then cut to five letters), so `configuracao` finds `configuração`,
  `autenticação` finds `autenticado`, `memory` finds `memories` and `links`
  finds `link`, while a memory holding the exact word ranks above one
  holding another form of it. The best 20 (or `--top N`) print newest first, capped
  like `recall`. Nothing is indexed on disk: 2,252 memories rank in ~50 ms.
- `brief <topic...>` prints a topic's best memories in `BRIEF_BYTES`, and
  `wake --brief <topic...>` adds them to the wake, after the memory and before
  `You are awake.`. Under `WAKE_BYTES` the memory gives up the room the brief
  prints, at most `BRIEF_BYTES` and never more than half the cap, and keeps
  it all when it cannot shrink that far. Lines the wake already prints are
  not repeated, nor is a stretch of memory already in the brief: a memory
  and the summaries above it are one fact at several zoom levels, and the
  best-scoring one stands for it. A topic with no match changes nothing. One log is one
  identity, so a project left alone decays out of the wake; the brief hands
  it back without splitting the store.
- `BRIEF_BYTES` (default 2500, 0 = none) joins the sizes `memo config` shows.
  The records are unchanged, but a `config` that sets `BRIEF_BYTES` is
  refused by 1.2.0 and older, which stop on any size they do not know: on a
  store shared with an older `memo`, leave it at its default.
- `check` reads the whole store and reports a memory not at its own offset, a
  record that is not a memory or not UTF-8, a blank or unreadable summary, or
  a partial record at the end of a file. It writes nothing and takes no lock.
- The setup block says what to note (decisions and why, corrections, facts
  about the user and their tools) and what not to (status: pushed, merged,
  PR or commit ids), to note before a long task ends or context is
  compacted, to run `find` before saying it does not know, and, when a fact
  changes, to note the new one saying which memory it supersedes. The nap
  prompt asks not to repeat the dates.
- README: the startup-hook recipe matches `startup|clear|compact` (a
  `SessionStart` hook is the one way to add context back after compaction)
  and passes `--brief` the repository's name; the 10,000-character cap and
  2 KB preview are stated for Claude Code 2.1.276; "What OptMem is not".

### Security

- Every error that echoes an argument, a config key or value, a path or a
  regex error passes it through the same cleaning as stored text: an escape
  sequence in any of them can no longer recolour or clear the terminal.
- `recall` refuses a pattern over 256 bytes or holding a control character,
  and, where the platform has a clock signal (not Windows), stops a pattern
  that backtracks past 5 seconds: `(a+)+$` on one line of a's never ends.
- Every append ends with `fsync` and, where the platform has it (macOS), the
  `F_FULLFSYNC` barrier SQLite and LMDB use: plain `fsync` there stops at the
  drive's write cache (0.03 ms measured, against 3 ms for the barrier), so an
  acknowledged memory could still vanish in a power cut. A level file created
  by a nap also has its directory synced, so the file itself survives. A test
  proves the order: write, flush, then the lock is released.
- An argument that is not UTF-8 is echoed cleaned in every error, where
  1.2.0 printed a traceback (`zoom`, `forget`, `config`, `import`, an unknown
  command).

### Fixed

- A capped wake with a `WAKE_LINES` far above the memory walked every budget
  down from T, each with a 60-step bisection: 16 s at 2,000 memories and
  minutes at 5,000. The walk now starts at `PART_LINES` at most (a capped
  wake is one part), each budget's cover comes from the largest thresholds,
  taken best first off a heap, and every block is expanded and rendered once: 20,000
  memories wake in under a second. A block whose own backlog of unpaid naps
  is past both budgets is not expanded further, so an imported history of
  200,000 unnapped memories costs a capped wake 0.05 s instead of the whole
  backlog. The wake of every store in the test matrix is unchanged.
- `forget` counts the summaries it drops instead of listing them.
- The stdin cap follows the memory's own `ENTRY_CHARS`, not the default.
- test.py: an unexpected exception is one failed check with its traceback,
  not the end of the run; every scratch directory is removed.

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
