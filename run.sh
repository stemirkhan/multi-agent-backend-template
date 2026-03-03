#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

usage() {
  cat <<'EOF'
Usage: ./run.sh [command]

Commands:
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

build_prompt() {
  local tz_file="$1"
  local prompt

  prompt="$(cat <<'EOF'
You are the Orchestrator for a FastAPI-only template. Do not propose another web stack.
Read `project-stack.toml` first. It is the machine-readable source of truth for language/framework/orm/migration_tool/test_runner, di_library, message_framework/message_broker/message_transport, cache/db, container_runtime/compose_tool, and api_runner/api_entrypoint. Do not make agents guess the stack if the profile is already filled in.
If `project-stack.toml` is missing, invalid, or contradicts the real project, fix it first as a template-level blocker.
Use __TZ_FILE__ as the primary product contract input.
Do not treat pre-existing `openapi.yaml` as source-of-truth; it may be absent or placeholder-only.
In Phase 2, API must generate or fully replace `openapi.yaml` from __TZ_FILE__ and architecture/DB contracts.
Before implementation, build a required operation inventory from __TZ_FILE__ (FR/US/acceptance) and map it to OpenAPI operationIds.
If __TZ_FILE__ implies endpoints missing from generated `openapi.yaml`, Phase 2 is not complete.
Work in Phase 1..5 iterations until all conditions are satisfied:
1) Required phase artifacts are updated out of template state:
   - docs/architecture.md -> Status != template
   - at least one docs/adr/ADR-*.md exists
   - openapi.yaml exists and x-template-status != template
   - docs/dev-environment.md -> Status != template
   - docs/schema-decisions.md -> Status != template
   - docs/test-matrix.md -> Status != template
   - docs/final-review.md -> Status != template
2) Test suite is green (`pytest -q` -> exit 0)
3) Gatekeeper reports no blocker findings
4) The acceptance checklist in __TZ_FILE__ is closed
5) Required operations are implemented and test-covered:
   - runtime handlers exist and are wired into FastAPI routers
   - for mutating operations, related service/repository and migration/schema changes exist
   - tests cover at least one success path and one negative/auth path per required operation
   - docs/test-matrix.md contains an operation coverage table (TZ requirement -> operationId -> tests)
6) The backend part has runtime code and/or migration and/or test changes (not only docs/.codex)
Validate phase completion by files, status markers, and operation-coverage evidence, not by agent summaries.
If the backend skeleton is missing or clearly does not match the stack profile, assign Worker with the `backend-bootstrap` skill first instead of starting feature implementation in an empty repository.
If the project has no reproducible dependency bootstrap entrypoint (`./scripts/dev-bootstrap.sh`, `make dev-bootstrap`, `task dev-bootstrap`, or equivalent), assign Devenv to bootstrap the environment first, and only then proceed to Worker/Tests/Monitor.
If implementation/tests need a running stack or API, assign Devenv first.
Do not let Worker/Tests/Monitor stall on ad hoc dependency installation; dependency bootstrap and startup flow belong to Devenv.
After each successfully closed phase, create one local checkpoint commit with `./scripts/phase-commit.sh` before moving on.
Commit message format: `phase-N: <short summary>`. Do not run `git push` automatically. Do not amend existing checkpoint commits.
In Phase 5, use only a bounded loop: one full review pass, at most one remediation pass, and one targeted re-review.
Full review pass: first run security-reviewer, consistency-reviewer, and performance-reviewer in parallel, then Gatekeeper.
If you find a blocker, initiate a CR yourself, assign the right agent, and do one remediation pass.
After remediation, rerun only the review domains affected by blocker findings, and only for changed files/flows from the blocker diff; do not ask review agents to scan the entire repository again.
Gatekeeper must explicitly confirm required operation coverage is complete; missing implemented operations are blockers.
If after remediation `pytest -q` exits with code 0 and Gatekeeper returns `pass`, close Phase 5 immediately with a checkpoint commit and do not start another review cycle.
If a blocker remains after the targeted re-review, stop the automation loop and return a short unresolved-blocker summary with the next owner instead of starting another automatic retry.
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
