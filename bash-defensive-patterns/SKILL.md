---
name: bash-defensive-patterns
description: Write or review production Bash with strict mode, traps, safe quoting, robust argument parsing, defensive file handling, idempotency, and clear logging. Use when creating shell scripts, CI helpers, deployment automation, or command-line utilities that must fail safely and behave predictably across edge cases.
---

# Bash Defensive Patterns

Use this skill when the user wants Bash that is safe under failure, predictable under odd input, and maintainable after the first draft.

## Quick Start

For a new script:

1. Start from [assets/script-template.sh](assets/script-template.sh).
2. Keep `set -Eeuo pipefail` unless the user explicitly needs different semantics.
3. Add `usage`, dependency checks, cleanup traps, and structured logging before implementing core logic.
4. Prefer small functions with validated inputs over long inline command chains.
5. Verify paths, required commands, and destructive operations before mutating state.
6. Run `scripts/validate_shell.sh <paths...>` before finishing. Do not treat the task as done while `shellcheck` failures remain.

For an existing script:

1. Inspect the header, traps, quoting, argument parsing, and cleanup flow first.
2. Look for unsafe patterns:
   unquoted expansions, `for f in $(...)`, implicit globals, unchecked `rm`, missing `mktemp`, weak signal handling, and hidden pipeline failures.
3. Tighten behavior without changing the intended CLI contract unless the user asks for it.
4. Run `scripts/validate_shell.sh <paths...>` and any available tests after edits.

## Validation Gate

Treat validation as part of the normal workflow, not as an optional cleanup pass.

Default completion criteria for any Bash file this skill edits:

1. `bash -n` passes.
2. `shellcheck` passes on the edited files.
3. If a ShellCheck suppression is necessary, keep it local and explain why in a brief comment.

Preferred command:

```bash
scripts/validate_shell.sh path/to/script.sh
```

If the skill is installed and you are working outside the skill folder, call the installed script directly:

```bash
"${CODEX_HOME:-$HOME/.codex}/skills/bash-defensive-patterns/scripts/validate_shell.sh" path/to/script.sh
```

## Default Build Pattern

Use this structure unless the script is trivial:

1. Shebang and strict mode
2. Global readonly metadata such as script name and directory
3. Logging helpers
4. Cleanup and signal traps
5. `usage`
6. Dependency checks
7. Argument parsing
8. Validation helpers
9. Main work functions
10. `main "$@"`

## Rules

- Quote expansions unless you have a specific reason not to.
- Prefer `[[ ... ]]` in Bash code.
- Prefer `printf` over `echo` for machine-relevant output.
- Use arrays for lists of paths, args, or commands.
- Use `mapfile` or NUL-delimited loops for filenames.
- Separate `local` declaration from command-substitution assignment when exit status matters.
- Avoid `cmd | while read ...` when the loop must update parent-shell state.
- Use `command -v` for dependency checks.
- Use `mktemp -d` plus `trap` for temporary state.
- Make destructive steps explicit and dry-runnable when feasible.
- Design reruns to be safe by default.
- Prefer fixing ShellCheck findings over suppressing them.

## Review Checklist

Check these before finishing:

- Strict mode is enabled or intentionally relaxed with a clear reason.
- Traps do not mask real failures and cleanup is idempotent.
- Argument parsing rejects malformed input cleanly.
- Required env vars and positional args are validated.
- All filesystem paths and command args are safely quoted.
- File iteration handles spaces, tabs, and glob characters.
- Command substitutions do not accidentally discard failure status behind `local var="$(cmd)"`.
- Pipelines and `while read` loops do not hide subshell-state bugs.
- Writes are atomic where partial output would be dangerous.
- Logs distinguish info, warning, and error paths.
- Background jobs are tracked and reaped correctly.
- The script survives re-execution without corrupting state.
- `bash -n` passes.
- `shellcheck` passes, or any remaining suppression is narrow and justified.

## References

- Read [references/patterns.md](references/patterns.md) for concrete examples:
  strict mode, `IFS` caveats, traps, temp files, arrays, argument parsing, logging, signals, file operations, idempotency, arithmetic, subshell pitfalls, dependency checks, and ShellCheck usage.
- Use [assets/script-template.sh](assets/script-template.sh) as the default starting point for new scripts.
- Use [scripts/validate_shell.sh](scripts/validate_shell.sh) as the standard Bash validation step.
