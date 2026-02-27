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
Ты Orchestrator FastAPI-only шаблона. Не предлагай другой web stack. Работай итерациями Phase 1..5, пока не выполнены все условия:
1) Обязательные фазовые артефакты обновлены из template-state:
   - docs/architecture.md -> Status != template
   - есть минимум один docs/adr/ADR-*.md
   - openapi.yaml -> x-template-status != template
   - docs/dev-environment.md -> Status != template
   - docs/schema-decisions.md -> Status != template
   - docs/test-matrix.md -> Status != template
   - docs/final-review.md -> Status != template
2) ./scripts/verify.sh -> exit 0
3) у Reviewer нет blocker-findings
4) Acceptance checklist в ${tz_file} закрыт.
5) Для backend-части есть изменения в runtime-коде и/или миграциях и/или тестах (не только docs/.codex).
Проверяй фазовые артефакты по файлам и статус-маркерам, а не по summary агентов.
Если для реализации/тестов/verify нужен поднятый стек или API — сначала назначай Devenv.
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
