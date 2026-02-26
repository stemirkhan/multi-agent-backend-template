#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<'EOF'
Usage: ./run.sh [command]

Commands:
  verify             Run project verification checks (default)
  codex [tz_file]    Run Codex multi-agent workflow (default tz_file: TZ_TEMPLATE.md)
  help               Show this help message
EOF
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

run_verify() {
  local verify_script="./scripts/verify.sh"

  if [[ ! -x "$verify_script" ]]; then
    printf 'Missing executable: %s\n' "$verify_script" >&2
    exit 1
  fi

  "$verify_script"
}

run_codex() {
  local tz_file="${1:-TZ_TEMPLATE.md}"

  if [[ $# -gt 1 ]]; then
    printf 'Too many arguments for codex command\n' >&2
    usage
    exit 1
  fi

  if ! have_cmd codex; then
    printf 'Command not found: codex\n' >&2
    exit 1
  fi

  if [[ ! -f "$tz_file" ]]; then
    printf 'TZ file not found: %s\n' "$tz_file" >&2
    exit 1
  fi

  local prompt
  prompt="Ты Orchestrator. Запусти multi-agent workflow по README.md и ${tz_file}: Architect -> (DB+API) -> Worker -> Tests+Monitor -> Reviewer. В конце дай сводку: что готово, что блокирует, кто следующий."

  codex --enable multi_agent "$prompt"
}

command_name="${1:-verify}"
if [[ $# -gt 0 ]]; then
  shift
fi

case "$command_name" in
  verify)
    run_verify "$@"
    ;;
  codex)
    run_codex "$@"
    ;;
  help|-h|--help)
    usage
    ;;
  *)
    printf 'Unknown command: %s\n\n' "$command_name" >&2
    usage
    exit 1
    ;;
esac
