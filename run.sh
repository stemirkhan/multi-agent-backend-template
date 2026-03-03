#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<'EOF'
Usage: ./run.sh [command]

Commands:
  check              Run local checks (`./scripts/check.sh`)
  codex [tz_file]    Run Codex via multi-agent profile (default)
  codex-auto [tz_file]
                     Run Codex via profile when available, override to --full-auto
  codex-danger [tz_file]
                     Run Codex via profile when available, override to danger-full-access
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

codex_profile_exists() {
  local config_path
  local profile_name
  local escaped_profile

  config_path="$(codex_config_path)"
  profile_name="$(codex_profile_name)"
  escaped_profile="${profile_name//./\\.}"

  if [[ ! -f "$config_path" ]]; then
    return 1
  fi

  grep -q "^\[profiles\.${escaped_profile}\]$" "$config_path"
}

print_profile_missing_warning() {
  local config_path
  local profile_name

  config_path="$(codex_config_path)"
  profile_name="$(codex_profile_name)"

  printf 'WARNING: Codex profile [%s] is missing in %s\n' "$profile_name" "$config_path" >&2
  printf 'Running without --profile for this invocation.\n' >&2
  printf 'Recommended profile snippet:\n' >&2
  printf '\n[profiles.%s]\napproval_policy = "never"\nsandbox_mode = "danger-full-access"\n\n' "$profile_name" >&2
}

run_check() {
  local check_script="./scripts/check.sh"

  if [[ ! -x "$check_script" ]]; then
    printf 'Missing executable: %s\n' "$check_script" >&2
    exit 1
  fi

  "$check_script"
}

build_prompt() {
  local tz_file="$1"
  local prompt

  prompt="$(cat <<'EOF'
You are the Orchestrator for a FastAPI-only template. Do not propose another web stack.
Read `project-stack.toml` first. It is the machine-readable source of truth for language/framework/orm/migration_tool/test_runner, di_library, message_framework/message_broker/message_transport, cache/db, container_runtime/compose_tool, and api_runner/api_entrypoint. Do not make agents guess the stack if the profile is already filled in.
If `project-stack.toml` is missing, invalid, or contradicts the real project, fix it first as a template-level blocker.
Use __TZ_FILE__ as the primary product contract input.
Use only these agents: `api`, `worker`, `tests`, `gatekeeper`.
Work in a simple 3-phase flow:
1) Contracts (`api`): generate or fully replace `openapi.yaml` from __TZ_FILE__, and build required operation inventory from FR/US/acceptance criteria.
2) Implementation (`worker`): implement required operations in runtime code (and persistence/migrations for mutating operations). If the repo lacks a coherent skeleton, start with `backend-bootstrap`. If dependencies are missing, run `./scripts/dev-bootstrap.sh`.
3) Validation + Gate (`tests` -> `gatekeeper`): add operation-level tests and run `./scripts/check.sh` (fallback: `pytest -q`), then publish final gate in `docs/final-review.md`.
Completion criteria:
- `openapi.yaml` exists and `x-template-status != template`.
- Required operations from __TZ_FILE__ are present in OpenAPI and implemented in runtime handlers.
- Tests include at least one success path and one negative/auth path per required operation.
- `./scripts/check.sh` exits with code 0.
- `docs/final-review.md` has `Status != template` and explicit pass/fail + blockers.
- Backend has runtime code and/or migration and/or test changes (not only docs/.codex).
Rules:
- No phase checkpoint commit requirements. Use normal task-focused commits only when needed.
- Do not loop endlessly after gate findings: at most one remediation pass, then return unresolved blockers with next owner.
Stop only if external input is required (secret, access, business decision); then ask one concrete question.
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
  local use_profile=0

  if [[ $# -gt 1 ]]; then
    printf 'Too many arguments for %s command\n' "$mode" >&2
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

  if codex_profile_exists; then
    use_profile=1
  fi

  prompt="$(build_prompt "$tz_file")"

  codex_args=()
  if [[ "$use_profile" -eq 1 ]]; then
    codex_args+=(--profile "$(codex_profile_name)")
  else
    print_profile_missing_warning
  fi

  if have_feature multi_agent; then
    codex_args+=(--enable multi_agent)
  fi

  case "$mode" in
    codex)
      if [[ "$use_profile" -eq 0 ]]; then
        codex_args+=(--ask-for-approval never --sandbox danger-full-access)
      fi
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

command_name="${1:-codex}"
if [[ $# -gt 0 ]]; then
  shift
fi

case "$command_name" in
  check)
    run_check "$@"
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
