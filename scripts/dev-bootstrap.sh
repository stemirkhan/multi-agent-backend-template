#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ ! -d ".venv" ]]; then
  python3 -m venv .venv
fi

if [[ -f "uv.lock" ]] && command -v uv >/dev/null 2>&1; then
  exec uv sync
fi

if [[ -f "requirements-dev.txt" ]]; then
  exec ./.venv/bin/python -m pip install -r requirements-dev.txt
fi

if [[ -f "requirements.txt" ]]; then
  exec ./.venv/bin/python -m pip install -r requirements.txt
fi

if [[ -f "pyproject.toml" ]]; then
  exec ./.venv/bin/python -m pip install -e '.[dev]'
fi

printf '%s\n' \
  "No supported dependency bootstrap manifest found." \
  "Expected one of: uv.lock, requirements-dev.txt, requirements.txt, pyproject.toml." >&2
exit 1
