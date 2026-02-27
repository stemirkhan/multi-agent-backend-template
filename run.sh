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
  prompt="$(cat <<EOF
Ты Orchestrator. Работай итерациями Phase 1..5, пока не выполнены все условия:
1) ./scripts/verify.sh -> exit 0
2) у Reviewer нет blocker-findings
3) Acceptance checklist в ${tz_file} закрыт.
4) Для backend-части есть изменения в runtime-коде и/или миграциях и/или тестах (не только docs/.codex).
Если находишь blocker — сам запускай CR, назначай нужного агента, вноси правки и перезапускай только нужные фазы.
Останавливайся только если нужен внешний ввод (секрет, доступ, бизнес-решение) — тогда задай один конкретный вопрос.
EOF
)"

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
