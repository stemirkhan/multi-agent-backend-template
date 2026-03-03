# Multi-Agent FastAPI Backend Template (Simplified)

This template runs a **FastAPI-only** multi-agent workflow with a simplified process.

Machine-readable stack profile: `project-stack.toml`
Primary product contract input: `TZ_TEMPLATE.md` (or your own TZ file)

## Workflow Goal

Deliver business API features with a minimal, predictable process:
- OpenAPI contract is generated from TZ and complete for in-scope requirements.
- Runtime code implements required operations.
- Tests are green via one check entrypoint.
- Final gate decision is written in `docs/final-review.md`.

## Simplified Model

### Agents (5 total)

- `orchestrator`
- `api`
- `worker`
- `tests`
- `gatekeeper`

### Phases (3 total)

1. `contracts` (`api`)
- Build required operation inventory from TZ.
- Generate/replace `openapi.yaml`.

2. `implementation` (`worker`)
- Implement required operations in runtime code.
- Add persistence/migrations for mutating operations when needed.

3. `validation+gate` (`tests` -> `gatekeeper`)
- Add operation-level tests (success + negative/auth).
- Run `./scripts/check.sh`.
- Publish final pass/fail in `docs/final-review.md`.

No phase checkpoint commit requirements.

## Required Outputs

Minimal mandatory outputs for a successful run:
- `openapi.yaml` with `x-template-status != template`
- runtime code and/or migration changes (not docs-only)
- tests for required operations
- `docs/final-review.md` with `Status != template` and explicit gate decision

## Quick Start

```bash
git clone https://github.com/stemirkhan/multi-agent-backend-template.git my-backend
cd my-backend
cp TZ_TEMPLATE.md backend_tz.md
./run.sh codex backend_tz.md
```

Less interactive:

```bash
./run.sh codex-auto backend_tz.md
```

## Local Commands

Run checks:

```bash
./run.sh check
# or directly
./scripts/check.sh
```

Run Codex orchestration:

```bash
./run.sh codex [tz_file]
./run.sh codex-auto [tz_file]
./run.sh codex-danger [tz_file]
```

Help:

```bash
./run.sh help
```

## Run Requirements

- `codex` in `PATH`
- optional profile in `~/.codex/config.toml` (default profile name: `multi_agent_backend`)

Recommended profile:

```toml
[profiles.multi_agent_backend]
approval_policy = "never"
sandbox_mode = "danger-full-access"
```

## Stack Defaults

- `python` + `fastapi`
- `sqlalchemy` + `alembic`
- `dishka`
- `faststream` + `redis-streams`
- `postgres` + `redis`
- `podman` + `podman-compose`
- API entrypoint: `app.main:app`
