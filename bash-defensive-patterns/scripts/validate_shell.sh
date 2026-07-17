#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
    cat <<'EOF'
Usage: validate_shell.sh <script-or-dir> [more-paths...]

Runs:
  1. bash -n on each discovered shell script
  2. shellcheck on the same files

Accepted inputs:
  - individual files
  - directories, scanned recursively for *.sh
EOF
}

if [[ $# -eq 0 ]]; then
    usage >&2
    exit 1
fi

if ! command -v bash >/dev/null 2>&1; then
    printf 'ERROR: bash is required\n' >&2
    exit 1
fi

if ! command -v shellcheck >/dev/null 2>&1; then
    printf 'ERROR: shellcheck is required\n' >&2
    exit 1
fi

declare -a files=()
declare -A seen=()

add_file() {
    local path="$1"

    [[ -f "$path" ]] || return 0

    if [[ "$path" == *.sh ]] || head -n 1 "$path" | grep -Eq '^#!.*/(env[[:space:]]+)?bash([[:space:]]|$)'; then
        if [[ -z "${seen[$path]:-}" ]]; then
            files+=("$path")
            seen["$path"]=1
        fi
    fi
}

for input_path in "$@"; do
    if [[ -d "$input_path" ]]; then
        while IFS= read -r -d '' path; do
            add_file "$path"
        done < <(find "$input_path" -type f -print0)
    elif [[ -e "$input_path" ]]; then
        add_file "$input_path"
    else
        printf 'ERROR: path not found: %s\n' "$input_path" >&2
        exit 1
    fi
done

if [[ ${#files[@]} -eq 0 ]]; then
    printf 'ERROR: no Bash shell scripts found in inputs\n' >&2
    exit 1
fi

printf 'Validating %s shell script(s)\n' "${#files[@]}" >&2

for path in "${files[@]}"; do
    printf 'bash -n %s\n' "$path" >&2
    bash -n "$path"
done

shellcheck "${files[@]}"
