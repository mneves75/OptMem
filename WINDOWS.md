# Windows support

OptMem now runs on native Windows (no WSL required).

## What changed
- `import fcntl` is guarded — falls back to `None` on platforms without it.
- `locked()` uses `msvcrt` advisory locking with spin/backoff when `fcntl`
  is unavailable, so parallel sessions (the documented multi-process case)
  queue instead of raising `Resource deadlock avoided`.
- The `.lock` file is opened in append mode (`"a"`) rather than `"w"`, which
  would truncate and break locks held by other processes on Windows.

## Known limits

None of the following has been run on Windows by this fork; it is read from
the code and the platform's documented behaviour.

- **Privacy.** `umask 077` sets POSIX modes, not NTFS ACLs. A store under
  `%USERPROFILE%` inherits the profile's owner-only ACL. A `MEMORY_DIR`
  anywhere else inherits that folder's ACL, so restrict it yourself, e.g.
  `icacls C:\path\to\mem /inheritance:r /grant:r "%USERNAME%":(OI)(CI)F`.
- **Handing a line over.** Printed orders use PowerShell's literal
  here-string, `@'` ... `'@ | memo note -`, which expands nothing. `cmd.exe`
  has no literal form: run memo from PowerShell or Git Bash.
- **Lock wait.** The `msvcrt` loop gives up after 30 s of actual sleep.

## Test (Windows native, no WSL)
```bat
python memo init
set MEMORY_DIR=C:\path\to\mem
python memo note "first memory"
python memo note "second memory"
python memo wake
```
Concurrency: 8 parallel `memo note` processes writing 1600 memories
resulted in 1600/1600 records persisted (lock verified).
