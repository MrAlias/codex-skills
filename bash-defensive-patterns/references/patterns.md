# Bash Defensive Patterns Reference

This reference holds the detailed pattern catalog. Load it when you need concrete snippets or when reviewing a script against a specific failure mode.

## Strict Mode

Enable strict mode at the top of Bash scripts unless compatibility requirements force a narrower setting.

```bash
#!/usr/bin/env bash
set -Eeuo pipefail
```

Key flags:

- `-E`: propagate `ERR` traps through functions and subshell contexts where supported
- `-e`: exit on unhandled non-zero statuses
- `-u`: fail on unset variables
- `-o pipefail`: fail a pipeline if any command in it fails

Some strict-mode guidance also narrows `IFS`:

```bash
IFS=$'\n\t'
```

Use that only when the script benefits from line-oriented word splitting. Do not rely on a global `IFS` change to fix unsafe expansion; quoting and arrays remain the primary defense.

## Error Trapping and Cleanup

Use cleanup handlers for temporary state and explicit error handlers when failures need context.

```bash
#!/usr/bin/env bash
set -Eeuo pipefail

tmpdir=""

cleanup() {
    if [[ -n "${tmpdir:-}" && -d "$tmpdir" ]]; then
        rm -rf -- "$tmpdir"
    fi
}

on_error() {
    local -r line="$1"
    printf 'ERROR: command failed at line %s\n' "$line" >&2
}

trap 'on_error "$LINENO"' ERR
trap cleanup EXIT

tmpdir="$(mktemp -d)"
```

## Variable Safety

Quote expansions to avoid word splitting and pathname expansion.

```bash
# Unsafe
cp $source $dest

# Safe
cp "$source" "$dest"

# Required variable
: "${REQUIRED_VAR:?REQUIRED_VAR is not set}"
```

Use `${var:-}` when a variable may be unset.

```bash
if [[ -z "${OPTIONAL_VAR:-}" ]]; then
    printf 'OPTIONAL_VAR is unset or empty\n' >&2
fi
```

## Array Handling

Use arrays for collections instead of space-delimited strings.

```bash
declare -a items=("item 1" "item 2" "item 3")

for item in "${items[@]}"; do
    printf 'Processing: %s\n' "$item"
done

mapfile -t lines < <(some_command)
readarray -t numbers < <(seq 1 10)
```

## Conditional Safety

Prefer `[[ ... ]]` for Bash scripts.

```bash
if [[ -f "$file" && -r "$file" ]]; then
    content=$(<"$file")
fi

if [[ -z "${VAR:-}" ]]; then
    printf 'VAR is not set or is empty\n' >&2
fi
```

Use `[ ... ]` only when POSIX shell compatibility is required.

## Safe Script Directory Detection

```bash
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
SCRIPT_NAME="$(basename -- "${BASH_SOURCE[0]}")"
```

## Function Template

Prefer explicit local variables and input validation.

```bash
validate_file() {
    local -r file="$1"
    local -r message="${2:-File not found: $file}"

    if [[ ! -f "$file" ]]; then
        printf 'ERROR: %s\n' "$message" >&2
        return 1
    fi
}

process_files() {
    local -r input_dir="$1"
    local -r output_dir="$2"

    [[ -d "$input_dir" ]] || {
        printf 'ERROR: input_dir is not a directory: %s\n' "$input_dir" >&2
        return 1
    }

    mkdir -p -- "$output_dir"

    while IFS= read -r -d '' file; do
        printf 'Processing: %s\n' "$file"
    done < <(find "$input_dir" -maxdepth 1 -type f -print0)
}
```

## Local Variables and Exit Status

When a value comes from command substitution, separate `local` declaration from assignment. This preserves the real exit status of the command.

```bash
load_config() {
    local config_path="$1"
    local config_text=""

    config_text="$(<"$config_path")" || return
    printf '%s\n' "$config_text"
}

load_generated_value() {
    local generated=""

    generated="$(generate_value)"
    local status=$?
    (( status == 0 )) || return "$status"
    printf '%s\n' "$generated"
}

bad_example() {
    # Avoid this pattern. $? is the exit status of local, not generate_value.
    local generated="$(generate_value)"
}
```

## Safe Temporary Files

```bash
tmpdir="$(mktemp -d)" || {
    printf 'ERROR: failed to create temp directory\n' >&2
    exit 1
}

trap 'rm -rf -- "$tmpdir"' EXIT

tmpfile1="$tmpdir/temp1.txt"
tmpfile2="$tmpdir/temp2.txt"
touch -- "$tmpfile1" "$tmpfile2"
```

## Robust Argument Parsing

```bash
VERBOSE=false
DRY_RUN=false
OUTPUT_FILE=""
THREADS=4

usage() {
    cat <<'EOF'
Usage: script.sh [OPTIONS]

Options:
  -v, --verbose       Enable verbose output
  -d, --dry-run       Run without making changes
  -o, --output FILE   Output file path
  -j, --jobs NUM      Number of parallel jobs
  -h, --help          Show this help message
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -o|--output)
            [[ $# -ge 2 ]] || {
                printf 'ERROR: missing value for %s\n' "$1" >&2
                exit 1
            }
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -j|--jobs)
            [[ $# -ge 2 ]] || {
                printf 'ERROR: missing value for %s\n' "$1" >&2
                exit 1
            }
            THREADS="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            printf 'ERROR: unknown option: %s\n' "$1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

[[ -n "$OUTPUT_FILE" ]] || {
    printf 'ERROR: -o/--output is required\n' >&2
    exit 1
}
```

## Structured Logging

```bash
timestamp() {
    date +'%Y-%m-%d %H:%M:%S'
}

log_info() {
    printf '[%s] INFO: %s\n' "$(timestamp)" "$*" >&2
}

log_warn() {
    printf '[%s] WARN: %s\n' "$(timestamp)" "$*" >&2
}

log_error() {
    printf '[%s] ERROR: %s\n' "$(timestamp)" "$*" >&2
}

log_debug() {
    if [[ "${DEBUG:-0}" == "1" ]]; then
        printf '[%s] DEBUG: %s\n' "$(timestamp)" "$*" >&2
    fi
}
```

## Process Orchestration and Signals

Track background processes explicitly and clean them up on termination.

```bash
declare -a PIDS=()

cleanup_children() {
    local pid=""

    for pid in "${PIDS[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            kill -TERM "$pid" 2>/dev/null || true
        fi
    done

    for pid in "${PIDS[@]}"; do
        wait "$pid" 2>/dev/null || true
    done
}

trap cleanup_children SIGINT SIGTERM

background_task &
PIDS+=("$!")

another_task &
PIDS+=("$!")

wait
```

## Pipes to While and Subshells

Do not pipe into `while read` when the loop needs to update state for later use. The loop runs in a subshell in common Bash setups.

```bash
last_line='NULL'

your_command | while read -r line; do
    if [[ -n "$line" ]]; then
        last_line="$line"
    fi
done

# Still NULL in the parent shell.
printf '%s\n' "$last_line"
```

Prefer process substitution or `readarray`:

```bash
last_line='NULL'

while read -r line; do
    if [[ -n "$line" ]]; then
        last_line="$line"
    fi
done < <(your_command)

printf '%s\n' "$last_line"
```

## Safe File Operations

```bash
safe_move() {
    local -r source="$1"
    local -r dest="$2"

    [[ -e "$source" ]] || {
        printf 'ERROR: source does not exist: %s\n' "$source" >&2
        return 1
    }

    [[ ! -e "$dest" ]] || {
        printf 'ERROR: destination already exists: %s\n' "$dest" >&2
        return 1
    }

    mv -- "$source" "$dest"
}

safe_rmdir() {
    local -r dir="$1"

    [[ -d "$dir" ]] || {
        printf 'ERROR: not a directory: %s\n' "$dir" >&2
        return 1
    }

    rm -rI -- "$dir"
}

atomic_write() {
    local -r target="$1"
    local tmpfile=""
    tmpfile="$(mktemp)" || return 1

    cat >"$tmpfile"
    mv -- "$tmpfile" "$target"
}
```

## Idempotent Script Design

```bash
ensure_directory() {
    local -r dir="$1"

    if [[ -d "$dir" ]]; then
        log_info "Directory already exists: $dir"
        return 0
    fi

    mkdir -p -- "$dir" || {
        log_error "Failed to create directory: $dir"
        return 1
    }

    log_info "Created directory: $dir"
}

ensure_config() {
    local -r config_file="$1"
    local -r default_value="$2"

    if [[ ! -f "$config_file" ]]; then
        printf '%s\n' "$default_value" >"$config_file"
        log_info "Created config: $config_file"
    fi
}
```

## Safe Command Substitution

```bash
name=$(<"$file")
output=$(command -v python3)

result=$(command -v node) || {
    log_error "node command not found"
    return 1
}

mapfile -t lines < <(grep "pattern" "$file")

while IFS= read -r -d '' file; do
    printf 'Processing: %s\n' "$file"
done < <(find /path -type f -print0)
```

## Expected Non-Zero Status Under Strict Mode

Some commands use non-zero statuses for normal control flow. Handle those explicitly instead of weakening strict mode globally.

```bash
count="$(grep -c 'needle' "$file" || true)"
```

When the exact return code matters, capture it deliberately:

```bash
set +e
grep -c 'needle' "$file"
status=$?
set -e

case "$status" in
    0|1)
        ;;
    *)
        printf 'ERROR: grep failed with status %s\n' "$status" >&2
        exit "$status"
        ;;
esac
```

For pipelines where later logic needs per-command status, inspect `PIPESTATUS` immediately after the pipeline:

```bash
grep 'needle' "$file" | sort | uniq
statuses=("${PIPESTATUS[@]}")

if (( statuses[0] != 0 && statuses[0] != 1 )); then
    printf 'ERROR: grep failed with status %s\n' "${statuses[0]}" >&2
    exit "${statuses[0]}"
fi
```

When chaining commands with `&&`, use a block if subsequent steps must be treated as one unit:

```bash
prepare_workspace && {
    generate_config
    run_job
}
publish_results
```

## Dry-Run Support

```bash
DRY_RUN="${DRY_RUN:-false}"

run_cmd() {
    if [[ "$DRY_RUN" == "true" ]]; then
        printf '[DRY RUN] Would execute:'
        printf ' %q' "$@"
        printf '\n'
        return 0
    fi

    "$@"
}
```

## Arithmetic Safety

Use shell arithmetic instead of `expr`, `let`, or string parsing.

```bash
local -i retries=0
local -i timeout_secs=30

(( retries += 1 ))
printf '%s\n' "$(( timeout_secs * 2 ))"
```

Be careful with `(( ... ))` under `set -e`: a false arithmetic expression returns status 1. Avoid bare post-increment expressions as standalone commands when zero is a valid intermediate value.

```bash
(( retries += 1 ))

if (( retries > max_retries )); then
    printf 'ERROR: too many retries\n' >&2
    exit 1
fi
```

## Named Parameters Pattern

```bash
process_data() {
    local input_file=""
    local output_dir=""
    local format="json"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --input=*)
                input_file="${1#*=}"
                ;;
            --output=*)
                output_dir="${1#*=}"
                ;;
            --format=*)
                format="${1#*=}"
                ;;
            *)
                printf 'ERROR: unknown parameter: %s\n' "$1" >&2
                return 1
                ;;
        esac
        shift
    done

    [[ -n "$input_file" ]] || {
        printf 'ERROR: --input is required\n' >&2
        return 1
    }
    [[ -n "$output_dir" ]] || {
        printf 'ERROR: --output is required\n' >&2
        return 1
    }
}
```

## Dependency Checking

```bash
check_dependencies() {
    local -a missing_deps=()
    local -a required=("jq" "curl" "git")
    local cmd=""

    for cmd in "${required[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        printf 'ERROR: missing required commands: %s\n' "${missing_deps[*]}" >&2
        return 1
    fi
}
```

## ShellCheck

Use ShellCheck as the default static-analysis gate for Bash work. Treat a failing ShellCheck run as unfinished work unless there is a narrow, justified suppression.

```bash
shellcheck script.sh
shellcheck scripts/*.sh
```

For this skill, prefer the bundled validator so syntax and ShellCheck run together:

```bash
scripts/validate_shell.sh path/to/script.sh
```

Prefer fixing the underlying issue over suppressing it. If suppression is necessary, keep it local and explain the reason:

```bash
# shellcheck disable=SC2016
printf '%s\n' 'literal $HOME placeholder for a generated config template'
```

Avoid broad file-level suppressions unless the whole file is intentionally written around a known tool limitation.

## Best Practices Summary

1. Always use strict mode unless compatibility requires otherwise.
2. Quote variable expansions.
3. Prefer `[[ ... ]]` in Bash.
4. Trap cleanup and important failure paths.
5. Validate inputs before doing work.
6. Use functions with clear names and local variables.
7. Log with timestamps and severity levels.
8. Support dry-run mode when the script mutates state.
9. Use `mktemp` for temporary files and directories.
10. Design reruns to be safe.
11. Document dependencies and assumptions.
12. Test both success and failure paths.
13. Use `command -v` instead of `which`.
14. Prefer `printf` over `echo`.

## External References

- Bash strict mode: <http://redsymbol.net/articles/unofficial-bash-strict-mode/>
- Google Shell Style Guide: <https://google.github.io/styleguide/shellguide.html>
- Defensive Bash Programming: <https://www.lifepipe.net/>
