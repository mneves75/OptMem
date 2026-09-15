# OptMem

Permanent memory for AI agents. A 426-token prompt, a script, plug and play.

![how OptMem works](anim/optmem.gif)

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/VictorTaelin/OptMem/main/install.sh | sh
```

It prints a `## Memory` block. Paste that at the top of your agent's
`AGENTS.md` (or `CLAUDE.md`), and you are done. Run the same line again to
update.

The tool lands at `~/.optmem/memo`; put `~/.optmem` on `PATH` to type `memo`.

## Commands

| | |
|---|---|
| `memo wake` | read the memory — the first command of every session |
| `memo note "..."` | record one memory: one line, up to 280 bytes |
| `memo nap` | answer the merges that came due |
| `memo recall <regex>` | search every memory ever recorded, word for word |
| `memo zoom <lo>-<hi>` | open a tree node into its two halves |
| `memo forget <lo>-<hi>` | drop a bad summary; the next nap rebuilds it |

Merges arrive one at a time, in the output of `note`. Nothing ever runs in the
background.

## Files

```
~/.optmem/
  memo          the tool: one file of Python 3, no dependencies
  memory/
    LOG.txt     every memory, one per line, append-only, never edited
    TREE/       the summaries: a cache, rebuildable from the log alone
    config      the sizes, written by `memo config`
```

```sh
memo config                  # show the sizes
memo config WAKE_LINES=300   # how many lines wake prints (96 ≈ 8k tokens)
memo config WAKE_LINES=      # back to the default
memo config WAKE_BYTES=9500  # cap wake's output in bytes (0 = no cap)
```

`WAKE_LINES` and `WAKE_BYTES` are reading budgets, not storage budgets: change
them whenever, in either direction, and nothing is recomputed.

### Waking from a startup hook

A hook prints once and is cut in place. Claude Code keeps 10,000 characters of
a hook's `additionalContext` and hands the agent a 2 KB preview of anything
longer, so a 96-line wake silently arrives as a few lines. Set `WAKE_BYTES`
below the cap and wake fits itself: it prints the finest memory, up to
`WAKE_LINES` lines, that fits in one part. A summary nobody has compressed yet
is shown as its halves, down to the raw memories, so a backlog of naps costs
bytes rather than the whole wake. When a pending compression does not fit
beside the memory, one line points at `memo nap` instead. A UTF-8 byte is never
fewer than one character, so a byte cap is also a character cap.

```sh
memo config WAKE_BYTES=9500   # leaves room for the hook's own preamble
```

```json
{"hooks": {"SessionStart": [{"hooks": [{"type": "command",
  "command": "~/.optmem/memo wake | jq -Rs '{hookSpecificOutput: {hookEventName: \"SessionStart\", additionalContext: .}}'"}]}]}}
```


Records are fixed width, so position *is* identity and every lookup is one
seek. At a million memories (608 MB), `wake` takes 0.03s.

Set `$MEMORY_DIR` to keep `memory/` elsewhere — a synced folder, a git repo.

## The prompt

This is what the installer prints, and the whole of the integration.

```markdown
## Memory

Your memory is OptMem:
- The tool is `~/.optmem/memo`
- Your memories are in `~/.optmem/memory`

OptMem outlives every session, compaction, model and vendor change.
Without it you do not know who you are, or what was decided and tried.

### At startup: activating OptMem (mandatory)

Run `~/.optmem/memo wake` before any other tool call, in every session, and
then do exactly what it prints, to the end of its output.

### While working: register memories (mandatory)

Call `~/.optmem/memo note "<1 line, max 280 bytes>"` whenever you learn
something new, or something worth keeping happens. That covers a task
worth real effort, a fact or insight the user teaches you, anything you
learn about their life (even indirectly), any event of lasting effect.

Do not register redundant memories.

If `~/.optmem/memo note` asks a compression: do it before your next action.

Never edit or delete anything under `~/.optmem/memory`: the tool manages it.

### When you need an old memory: search, or navigate

`~/.optmem/memo recall <regex>` searches every memory, word for word.

Your memories also form a binary tree: #0-1, #2-3 ... exist as one-line
summaries, pairs of those as #0-3, and so on -- every `#a-b` line wake
prints is one node of it. `~/.optmem/memo zoom <a-b>` opens a node into its
two halves, down to the raw memories.

### If you're a subagent: skip everything above

Parallel sessions on this machine are all you, and may all write memories.
A subagent is not: it must never run `memo`, because it cannot judge what
is already known, and its notes would arrive duplicated and incorrectly.
When you spawn one, write: `You are a subagent. Don't run memo.`
```
