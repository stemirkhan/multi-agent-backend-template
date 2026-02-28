#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

FAILED=0
CHECKS_RUN=0

log() {
  printf '%s\n' "$1"
}

run_check() {
  local name="$1"
  shift

  CHECKS_RUN=$((CHECKS_RUN + 1))
  log "==> $name"

  if "$@"; then
    log "OK: $name"
  else
    log "FAIL: $name"
    FAILED=$((FAILED + 1))
  fi

  printf '\n'
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

check_agent_toml_parse() {
  if ! have_cmd python3; then
    log "python3 not found"
    return 1
  fi

  python3 - <<'PY'
import pathlib
import sys

try:
    import tomllib
except ModuleNotFoundError:
    print("tomllib is unavailable (need Python 3.11+)")
    sys.exit(1)

agent_dir = pathlib.Path(".codex") / "agents"
files = sorted(agent_dir.glob("*.toml"))
if not files:
    print("No agent TOML files found in .codex/agents")
    sys.exit(1)

required_keys = ("model", "model_reasoning_effort", "developer_instructions")
errors = 0

for path in files:
    data = tomllib.loads(path.read_text(encoding="utf-8"))
    missing = [key for key in required_keys if key not in data]
    if missing:
        print(f"{path}: missing keys: {', '.join(missing)}")
        errors += 1

if errors:
    sys.exit(1)

print(f"Validated {len(files)} agent TOML files")
PY
}

check_required_agents_present() {
  local required=(
    "api"
    "architect"
    "consistency-reviewer"
    "db"
    "devenv"
    "explorer"
    "gatekeeper"
    "monitor"
    "orchestrator"
    "performance-reviewer"
    "security-reviewer"
    "tests"
    "worker"
  )
  local missing=0

  for agent in "${required[@]}"; do
    if [[ ! -f ".codex/agents/${agent}.toml" ]]; then
      log "Missing .codex/agents/${agent}.toml"
      missing=1
    fi
  done

  [[ "$missing" -eq 0 ]]
}

check_readme_verify_entrypoint() {
  if [[ ! -f "README.md" ]]; then
    log "README.md is missing"
    return 1
  fi

  if ! grep -q "./scripts/verify.sh" README.md; then
    log "README.md does not mention ./scripts/verify.sh"
    return 1
  fi

  return 0
}

check_local_security_defaults() {
  local has_errors=0

  if [[ ! -f ".env.example" ]]; then
    log "Missing .env.example"
    has_errors=1
  else
    local required_vars=(
      "APP_ENV="
      "APP_HOST="
      "APP_PORT="
      "LOG_LEVEL="
      "POSTGRES_DSN="
      "REDIS_DSN="
      "JWT_SECRET="
    )

    for var in "${required_vars[@]}"; do
      if ! grep -q "^${var}" ".env.example"; then
        log ".env.example is missing ${var}"
        has_errors=1
      fi
    done
  fi

  if [[ ! -f ".gitignore" ]]; then
    log "Missing .gitignore"
    has_errors=1
  else
    if ! grep -q "^\\.env$" ".gitignore"; then
      log ".gitignore does not ignore .env"
      has_errors=1
    fi

    if ! grep -q "^!\\.env\\.example$" ".gitignore"; then
      log ".gitignore does not allow tracking .env.example"
      has_errors=1
    fi
  fi

  [[ "$has_errors" -eq 0 ]]
}

check_project_stack_profile() {
  if ! have_cmd python3; then
    log "python3 not found"
    return 1
  fi

  python3 - <<'PY'
import pathlib
import sys

try:
    import tomllib
except ModuleNotFoundError:
    print("tomllib is unavailable (need Python 3.11+)")
    sys.exit(1)

path = pathlib.Path("project-stack.toml")
if not path.is_file():
    print("project-stack.toml is missing")
    sys.exit(1)

data = tomllib.loads(path.read_text(encoding="utf-8"))
required = {
    "schema_version": int,
    "language": str,
    "framework": str,
    "orm": str,
    "migration_tool": str,
    "test_runner": str,
    "di_library": str,
    "message_framework": str,
    "message_broker": str,
    "message_transport": str,
    "cache": str,
    "db": str,
    "container_runtime": str,
    "compose_tool": str,
    "api_runner": str,
    "api_entrypoint": str,
    "verify_entrypoint": str,
}

errors = 0

for key, expected_type in required.items():
    if key not in data:
        print(f"project-stack.toml: missing key: {key}")
        errors += 1
        continue

    value = data[key]
    if expected_type is int:
        if not isinstance(value, int):
            print(f"project-stack.toml: {key} must be an integer")
            errors += 1
    else:
        if not isinstance(value, str) or not value.strip():
            print(f"project-stack.toml: {key} must be a non-empty string")
            errors += 1

if data.get("schema_version") != 1:
    print("project-stack.toml: schema_version must be 1")
    errors += 1

if data.get("language") != "python":
    print("project-stack.toml: language must be python for this template")
    errors += 1

if data.get("framework") != "fastapi":
    print("project-stack.toml: framework must be fastapi for this template")
    errors += 1

verify_entrypoint = data.get("verify_entrypoint")
if isinstance(verify_entrypoint, str) and verify_entrypoint.strip():
    verify_path = pathlib.Path(verify_entrypoint)
    if verify_entrypoint.startswith("./"):
        verify_path = pathlib.Path(verify_entrypoint[2:])
    if not verify_path.is_file():
        print(f"project-stack.toml: verify_entrypoint target does not exist: {verify_entrypoint}")
        errors += 1

if errors:
    sys.exit(1)

print("Validated project-stack.toml")
PY
}

check_default_phase_artifacts_present() {
  local has_errors=0
  local markdown_artifacts=(
    "docs/architecture.md"
    "docs/dev-environment.md"
    "docs/schema-decisions.md"
    "docs/test-matrix.md"
    "docs/final-review.md"
  )

  for path in "${markdown_artifacts[@]}"; do
    if [[ ! -f "$path" ]]; then
      log "Missing ${path}"
      has_errors=1
      continue
    fi

    if ! grep -q "^Status:" "$path"; then
      log "Missing Status header in ${path}"
      has_errors=1
    fi
  done

  if [[ ! -d "docs/adr" ]]; then
    log "Missing docs/adr/"
    has_errors=1
  fi

  if [[ ! -f "docs/adr/README.md" ]]; then
    log "Missing docs/adr/README.md"
    has_errors=1
  fi

  if [[ ! -f "openapi.yaml" ]]; then
    log "Missing openapi.yaml"
    has_errors=1
  else
    if ! grep -q "^openapi:" "openapi.yaml"; then
      log "openapi.yaml does not declare an OpenAPI version"
      has_errors=1
    fi

    if ! grep -q "^x-template-status:" "openapi.yaml"; then
      log "openapi.yaml is missing x-template-status"
      has_errors=1
    fi
  fi

  [[ "$has_errors" -eq 0 ]]
}

check_project_skills() {
  local validator="/home/temirkhan/.codex/skills/.system/skill-creator/scripts/quick_validate.py"
  local required_skills=(
    "change-request-writer"
    "architecture-decision-record"
    "db-design-checklist"
    "backend-bootstrap"
  )
  local has_errors=0

  for skill in "${required_skills[@]}"; do
    local skill_dir=".codex/skills/${skill}"
    local skill_md="${skill_dir}/SKILL.md"
    local ui_yaml="${skill_dir}/agents/openai.yaml"

    if [[ ! -f "$skill_md" ]]; then
      log "Missing ${skill_md}"
      has_errors=1
      continue
    fi

    if [[ ! -f "$ui_yaml" ]]; then
      log "Missing ${ui_yaml}"
      has_errors=1
      continue
    fi

    if [[ "$skill" == "backend-bootstrap" ]]; then
      local required_refs=(
        "${skill_dir}/references/project-layout.md"
        "${skill_dir}/references/exception-layer.md"
        "${skill_dir}/references/bootstrap-checklist.md"
        "${skill_dir}/references/settings-and-secrets.md"
        "${skill_dir}/references/service-repository-boundaries.md"
        "${skill_dir}/references/code-quality.md"
      )

      for ref in "${required_refs[@]}"; do
        if [[ ! -f "$ref" ]]; then
          log "Missing ${ref}"
          has_errors=1
        fi
      done
    fi

    if grep -q "\\[TODO:" "$skill_md"; then
      log "Skill contains TODO placeholders: ${skill_md}"
      has_errors=1
    fi

    if ! grep -q "^name: ${skill}$" "$skill_md"; then
      log "Skill name mismatch in ${skill_md}"
      has_errors=1
    fi

    if [[ -f "$validator" ]]; then
      if ! python3 "$validator" "$skill_dir" >/dev/null; then
        log "Skill failed quick validation: ${skill_dir}"
        has_errors=1
      fi
    fi
  done

  [[ "$has_errors" -eq 0 ]]
}

run_check "Parse agent TOML files" check_agent_toml_parse
run_check "Required agents are present" check_required_agents_present
run_check "Local security defaults are present" check_local_security_defaults
run_check "Project stack profile is present and valid" check_project_stack_profile
run_check "README references verify entrypoint" check_readme_verify_entrypoint
run_check "Default phase artifacts are present" check_default_phase_artifacts_present
run_check "Project skills are present and valid" check_project_skills

if [[ "$CHECKS_RUN" -eq 0 ]]; then
  log "No checks were executed"
  exit 2
fi

if [[ "$FAILED" -ne 0 ]]; then
  log "Verification failed: ${FAILED} check(s) failed"
  exit 1
fi

log "Verification passed: ${CHECKS_RUN} check(s) succeeded"
exit 0
