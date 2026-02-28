#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<'EOF'
Usage: ./run.sh [command]

Commands:
  verify             Run project verification checks (default)
  codex [tz_file]    Run Codex via the required multi-agent profile
  codex-auto [tz_file]
                     Run Codex via the profile, but override to --full-auto
  codex-danger [tz_file]
                     Run Codex via the profile, but override to danger-full-access
  help               Show this help message
EOF
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

have_feature() {
  local feature_name="$1"

  if ! have_cmd codex; then
    return 1
  fi

  codex features list 2>/dev/null | awk '{print $1}' | grep -qx "$feature_name"
}

codex_config_path() {
  printf '%s' "${CODEX_HOME:-$HOME/.codex}/config.toml"
}

codex_profile_name() {
  printf '%s' "${CODEX_MULTI_AGENT_PROFILE:-multi_agent_backend}"
}

ensure_codex_profile() {
  local config_path
  local profile_name

  config_path="$(codex_config_path)"
  profile_name="$(codex_profile_name)"

  if [[ ! -f "$config_path" ]]; then
    printf 'Codex config not found: %s\n' "$config_path" >&2
    printf 'Create profile [%s] in that file before running multi-agent template.\n' "$profile_name" >&2
    exit 1
  fi

  if ! grep -q "^\[profiles\.${profile_name//./\\.}\]$" "$config_path"; then
    printf 'Required Codex profile is missing: %s\n' "$profile_name" >&2
    printf 'Add this to %s:\n' "$config_path" >&2
    printf '\n[profiles.%s]\napproval_policy = "never"\nsandbox_mode = "danger-full-access"\n' "$profile_name" >&2
    exit 1
  fi
}

run_verify() {
  local verify_script="./scripts/verify.sh"

  if [[ ! -x "$verify_script" ]]; then
    printf 'Missing executable: %s\n' "$verify_script" >&2
    exit 1
  fi

  "$verify_script"
}

build_prompt() {
  local tz_file="$1"
  local prompt

  prompt="$(cat <<'EOF'
Ты Orchestrator FastAPI-only шаблона. Не предлагай другой web stack.
Сначала прочитай `project-stack.toml`. Это machine-readable source of truth для language/framework/orm/migration_tool/test_runner, di_library, message_framework/message_broker/message_transport, cache/db, container_runtime/compose_tool, api_runner/api_entrypoint и verify_entrypoint. Не заставляй агентов гадать стек, если профиль уже заполнен.
Если `project-stack.toml` отсутствует, невалиден или противоречит реальности проекта — сначала исправь это как template-level blocker.
Работай итерациями Phase 1..5, пока не выполнены все условия:
1) Обязательные фазовые артефакты обновлены из template-state:
   - docs/architecture.md -> Status != template
   - есть минимум один docs/adr/ADR-*.md
   - openapi.yaml -> x-template-status != template
   - docs/dev-environment.md -> Status != template
   - docs/schema-decisions.md -> Status != template
   - docs/test-matrix.md -> Status != template
   - docs/final-review.md -> Status != template
2) ./scripts/verify.sh -> exit 0
3) у Gatekeeper нет blocker-findings
4) Acceptance checklist в __TZ_FILE__ закрыт.
5) Для backend-части есть изменения в runtime-коде и/или миграциях и/или тестах (не только docs/.codex).
Проверяй фазовые артефакты по файлам и статус-маркерам, а не по summary агентов.
Если backend skeleton отсутствует или явно не соответствует stack profile, сначала назначай Worker со skill `backend-bootstrap`, а не начинай feature implementation в пустом репозитории.
Если в проекте нет reproducible bootstrap entrypoint для зависимостей (`./scripts/dev-bootstrap.sh`, `make dev-bootstrap`, `task dev-bootstrap` или эквивалент), сначала назначай Devenv на bootstrap среды, а уже потом Worker/Tests/Monitor.
Если для реализации/тестов/verify нужен поднятый стек или API — сначала назначай Devenv.
Не позволяй Worker/Tests/Monitor зависать на ad-hoc установке зависимостей; dependency bootstrap и startup flow — зона ответственности Devenv.
После каждого успешно закрытого Phase делай один локальный checkpoint commit через `./scripts/phase-commit.sh`, прежде чем переходить к следующему Phase.
Формат commit message: `phase-N: <short summary>`. Не делай `git push` автоматически. Не amend'и уже созданные checkpoint commits.
В Phase 5 сначала запускай security-reviewer, consistency-reviewer и performance-reviewer параллельно, затем Gatekeeper.
Если находишь blocker — сам запускай CR, назначай нужного агента, вноси правки и перезапускай только нужные фазы.
Останавливайся только если нужен внешний ввод (секрет, доступ, бизнес-решение) — тогда задай один конкретный вопрос.
EOF
)"

  printf '%s' "${prompt//__TZ_FILE__/$tz_file}"
}

run_codex() {
  local mode="$1"
  shift
  local tz_file="${1:-TZ_TEMPLATE.md}"
  local prompt
  local -a codex_args

  if [[ $# -gt 1 ]]; then
    printf 'Too many arguments for %s command\n' "$mode" >&2
    usage
    exit 1
  fi

  if ! have_cmd codex; then
    printf 'Command not found: codex\n' >&2
    exit 1
  fi

  ensure_codex_profile

  if [[ ! -f "$tz_file" ]]; then
    printf 'TZ file not found: %s\n' "$tz_file" >&2
    exit 1
  fi

  prompt="$(build_prompt "$tz_file")"

  codex_args=()
  codex_args+=(--profile "$(codex_profile_name)")
  if have_feature multi_agent; then
    codex_args+=(--enable multi_agent)
  fi

  case "$mode" in
    codex)
      ;;
    codex-auto)
      codex_args+=(--full-auto)
      ;;
    codex-danger)
      codex_args+=(--dangerously-bypass-approvals-and-sandbox)
      ;;
    *)
      printf 'Unknown Codex mode: %s\n' "$mode" >&2
      exit 1
      ;;
  esac

  codex "${codex_args[@]}" "$prompt"
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
    run_codex codex "$@"
    ;;
  codex-auto)
    run_codex codex-auto "$@"
    ;;
  codex-danger)
    run_codex codex-danger "$@"
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
