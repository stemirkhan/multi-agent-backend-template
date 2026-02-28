#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<'EOF'
Usage: ./scripts/phase-commit.sh <phase> [summary]

Examples:
  ./scripts/phase-commit.sh 1 "architecture and adr"
  ./scripts/phase-commit.sh phase-3 "bootstrap and implementation"
EOF
}

if [[ $# -lt 1 ]]; then
  usage >&2
  exit 1
fi

phase_arg="$1"
shift

if [[ "$phase_arg" =~ ^[0-9]+$ ]]; then
  phase_label="phase-${phase_arg}"
elif [[ "$phase_arg" =~ ^phase-[0-9]+$ ]]; then
  phase_label="$phase_arg"
else
  printf 'Invalid phase value: %s\n' "$phase_arg" >&2
  exit 1
fi

summary="${*:-checkpoint}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  printf 'Not a git repository: %s\n' "$ROOT_DIR" >&2
  exit 1
fi

if ! git config user.email >/dev/null 2>&1; then
  printf 'git user.email is not configured\n' >&2
  exit 1
fi

if ! git config user.name >/dev/null 2>&1; then
  printf 'git user.name is not configured\n' >&2
  exit 1
fi

if [[ -z "$(git status --short)" ]]; then
  printf 'No changes to commit for %s\n' "$phase_label"
  exit 0
fi

git add -A

if git diff --cached --quiet; then
  printf 'No staged changes to commit for %s\n' "$phase_label"
  exit 0
fi

git commit -m "${phase_label}: ${summary}"
