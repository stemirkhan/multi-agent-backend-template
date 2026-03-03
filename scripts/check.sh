#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

find_tool() {
  local venv_path="$1"
  local global_name="$2"

  if [[ -x "$venv_path" ]]; then
    printf '%s' "$venv_path"
    return 0
  fi

  if command -v "$global_name" >/dev/null 2>&1; then
    printf '%s' "$global_name"
    return 0
  fi

  return 1
}

if [[ -d "tests" ]] && find tests -type f \( -name "test_*.py" -o -name "*_test.py" \) | grep -q .; then
  if ! PYTEST_BIN="$(find_tool "./.venv/bin/pytest" "pytest")"; then
    printf 'pytest is required but not found. Run ./scripts/dev-bootstrap.sh first.\n' >&2
    exit 1
  fi

  "$PYTEST_BIN" -q
else
  printf 'No tests found under ./tests, skipping pytest.\n'
fi

if RUFF_BIN="$(find_tool "./.venv/bin/ruff" "ruff")"; then
  "$RUFF_BIN" check .
fi
