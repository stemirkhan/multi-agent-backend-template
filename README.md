# Multi-Agent FastAPI Backend Workflow Template

This README describes how a multi-agent team can work on a FastAPI backend project using this template.
The template is fixed to a FastAPI stack and is not intended for other web frameworks without explicit adaptation.

Detailed end-to-end explanation: `docs/TEMPLATE_DETAILED_GUIDE.md`
Machine-readable stack profile: `project-stack.toml`

## Goal

Build a backend where:

- architectural decisions are locked and agreed;
- API and DB are compatible and stable;
- required business operations from the spec/OpenAPI are fully implemented, not left as a bootstrap-only skeleton;
- tests and verify runs are green;
- there are no blocker risks in security or correctness.

## Create A New Backend From This Template

1. Copy this template into a new repository.
2. Prepare `TZ_TEMPLATE.md` (or your own TZ file) as the primary input contract.
3. Keep `project-stack.toml` defaults unless your real stack differs.
4. Add or clarify reproducible project entrypoints if they are already known:
   - `./scripts/dev-bootstrap.sh`
   - `./scripts/dev-up.sh`
   - `./scripts/dev-api.sh`
   - `make dev-bootstrap`
   - `make dev-up`
   - `make run-api`
   - `make verify`
5. Verify the template:

```bash
./run.sh verify
```

6. Run the first multi-agent pass:

```bash
./run.sh codex
```

or:

```bash
./run.sh codex backend_tz_from_template.md
```

If the new repository does not yet have a runnable backend skeleton, Orchestrator should route Worker to the `backend-bootstrap` skill before feature-level implementation begins.

## Quick Start With GitHub

### Option A. New project in an empty folder

```bash
git clone https://github.com/stemirkhan/multi-agent-backend-template.git my-backend
cd my-backend
cp TZ_TEMPLATE.md backend_tz_from_template.md
./run.sh verify
./run.sh codex backend_tz_from_template.md
```

If you want a less interactive run:

```bash
./run.sh codex-auto backend_tz_from_template.md
```

If you are on an isolated dev machine and do not want to stop on approvals/sandbox:

```bash
./run.sh codex-danger backend_tz_from_template.md
```

### Option B. Merge the template into an existing backend repo

If your project directory is not empty, `git clone ... .` is not a good approach. A safer path is:

```bash
cd /path/to/existing-backend
git clone https://github.com/stemirkhan/multi-agent-backend-template.git /tmp/mab-template
rsync -av --exclude '.git' /tmp/mab-template/ ./
rm -rf /tmp/mab-template
chmod +x run.sh scripts/verify.sh scripts/dev-bootstrap.sh
./run.sh verify
./run.sh codex backend_tz_from_template.md
```

Important:

- do not move the template `.git` into your existing project;
- keep your own origin and git history;
- review `project-stack.toml` and the spec before the first run.

## What the user must fill in

Before the first run, the user must explicitly provide this input:

- `TZ_TEMPLATE.md` or `backend_tz_from_template.md`: MVP goal, FR/NFR, API/DB assumptions, RBAC, acceptance checklist.

Template defaults are pre-filled:

- `project-stack.toml` is preconfigured for the FastAPI template stack and can stay unchanged unless the real stack differs.
- `openapi.yaml` is not required from user input and must be generated/replaced by agents in Phase 2 from TZ requirements.

Nice to have in advance:

- a project-specific `README.md` section with run/test commands if they differ from the template defaults;
- `./scripts/dev-bootstrap.sh`, `./scripts/dev-up.sh`, `./scripts/dev-api.sh` or `make`/`task` entrypoints if the local bootstrap/startup flow is already known;
- `.env.example` if the project already needs local settings and secret variables.

Do not pre-fill phase artifacts in `docs/*.md` before running. `openapi.yaml` should be generated/replaced by agents from TZ requirements during Phase 2.

## Stack assumptions

Source of truth for stack and runtime tooling: `project-stack.toml`

Default profile:

- Language/framework: `python` + `fastapi`
- Schemas/validation: `Pydantic`
- Persistence/migrations: `SQLAlchemy` + `Alembic`
- DI: `dishka`
- Messaging: `faststream` + `redis` / `redis-streams`
- Cache/DB: `redis` + `postgres`
- Dev containers: `podman` + `podman-compose`
- API runtime: `uvicorn` -> `app.main:app`
- Verify entrypoint: `./scripts/verify.sh`

`project-stack.toml` is not a version lockfile. It is a machine-readable profile of technology choices and entrypoints that agents must read before making assumptions.

## Built-in Skills

- `architecture-decision-record`: records architecture decisions as ADRs.
- `change-request-writer`: writes contract change requests between roles.
- `db-design-checklist`: runs schema/migration decisions through a strict checklist.
- `backend-bootstrap`: creates an initial FastAPI backend skeleton (runtime structure, dev entrypoints, test foundation, custom exception layer).

## Template Hard Defaults

- Unified error layer: app-level exceptions with `code`, `message`, `details`; API must not expose secrets, PII, or internal technical details.
- Local configuration via env: `.env` is not committed, `.env.example` is committed, settings are read via `pydantic-settings`.
- `Service` / `Repository` boundary: services own business logic and transaction/UoW; repositories do not do `commit` / `rollback` and do not contain business logic.
- Naming: service classes end with `Service`, repositories end with `Repository`.
- Basic code quality: formatter, linter, and type hints for public interfaces.

## Agent Roles

## Orchestrator

- Manages phases and execution order.
- Does not write production code and does not change the DB schema directly.
- Resolves conflicts between contracts.

## Architect

- Locks architecture decisions (queues, cache, security boundaries, consistency model).
- Writes the architecture contract in `docs/architecture.md` and ADRs in `docs/adr/ADR-*.md`.
- Escalates contract changes through Change Requests.

## DB

- Owns the data schema, migrations, and indexes.
- Maintains schema-level decisions in `docs/schema-decisions.md`.
- Owns constraints, integrity, and migration safety.
- Does not change API contracts without a Change Request.

## API

- Owns the public FastAPI contract in `openapi.yaml` (OpenAPI, request/response schemas, errors, idempotency).
- Checks compatibility with DB and architecture.
- Does not change the DB directly.

## Devenv

- Owns the local dev environment and reproducible startup flow.
- Treats `project-stack.toml` as the source of truth for container runtime, compose tool, and API entrypoint.
- Starts dependencies and the API when needed.
- Uses `podman` and `podman-compose` for containerized dev by default.
- Maintains `docs/dev-environment.md` as the canonical runtime/bootstrap artifact.

## Worker

- Implements the FastAPI runtime: business logic, services, repositories, and integrations.
- Reads `project-stack.toml` for runtime/DI/messaging assumptions before implementation.
- Follows Architect/DB/API contracts.
- Does not change architecture or contracts without explicit agreement.

## Tests

- Writes unit/integration/contract/security tests.
- Reads `project-stack.toml` for test runner, DB/cache/message infra, and verify entrypoint.
- Uses FastAPI/ASGI runtime for integration/contract scenarios.
- Maintains `docs/test-matrix.md` as the canonical test coverage list.
- Maintains the access matrix and negative scenarios.
- Does not rewrite production code without need.

## Security Reviewer (read-only)

- Checks broken access control, ownership, auth/RBAC gaps, and secret leakage.
- Does not change code and does not publish the final gate.

## Consistency Reviewer (read-only)

- Checks idempotency, transaction boundaries, race conditions, and duplicate side effects.
- Does not change code and does not publish the final gate.

## Performance Reviewer (read-only)

- Checks N+1, indexes, heavy sorts, query shape, and FastAPI + DB bottlenecks.
- Does not change code and does not publish the final gate.

## Gatekeeper

- Waits for the review agents and aggregates findings.
- Publishes the final gate and maintains `docs/final-review.md`.
- Does not perform a deep audit instead of specialized review agents.

## Explorer (read-only)

- Analyzes the project structure, spec, and contracts.
- Finds contradictions and gaps in requirements.

## Monitor (read-only)

- Runs the single verify entrypoint and summarizes results.
- Treats `project-stack.toml` as the source of truth for verify entrypoint and container runtime.
- Does not change code.

## Verify entrypoint order

Machine-readable source of truth for verify: `project-stack.toml` (`verify_entrypoint`).

If the stack profile entrypoint is missing or temporarily invalid, Monitor/Tests use the fallback order:

1. `./scripts/verify.sh`
2. `make verify`
3. `task verify`
4. fallback: commands from the README "How to test" section

If dev uses containers, the default standard is `podman` + `podman-compose`.

## Workflow by phases

Phase 1: Architecture

- Architect locks architecture decisions and constraints.
- Phase artifacts: `docs/architecture.md` and at least one `docs/adr/ADR-*.md`.
- After successful phase closure, Orchestrator creates a local checkpoint commit.

Phase 2: Contracts

- DB and API run in parallel.
- Orchestrator checks contract compatibility and required operation coverage derived from TZ.
- Phase artifacts: `openapi.yaml` and `docs/schema-decisions.md`.
- API must generate or replace `openapi.yaml` from TZ requirements (not reuse placeholder-only content).
- Phase 2 is not complete if business requirements imply endpoints that are missing from generated `openapi.yaml`.
- After successful phase closure, Orchestrator creates a local checkpoint commit.

Phase 3: Dev environment + implementation

- Devenv prepares the local dev environment and starts services/API when needed.
- Worker implements strictly against the contracts in real backend runtime code.
- Phase artifact: `docs/dev-environment.md`.
- Documentation-only changes do not count as finishing Phase 3.
- After successful phase closure, Orchestrator creates a local checkpoint commit.

Phase 4: Testing

- Tests add/update tests.
- Monitor runs the verify entrypoint and publishes the result.
- Phase artifact: `docs/test-matrix.md`.
- `docs/test-matrix.md` must include operation coverage mapping (`TZ requirement -> operationId -> tests`) for all in-scope operations.
- After successful phase closure, Orchestrator creates a local checkpoint commit.

Phase 5: Review

- Security Reviewer, Consistency Reviewer, and Performance Reviewer run in parallel.
- Gatekeeper aggregates findings and publishes the final gate.
- If there is a blocker, the task returns to the appropriate owner.
- Phase artifact: `docs/final-review.md`.
- After successful phase closure, Orchestrator creates a local checkpoint commit.

Checkpoint commit message format:

- `phase-1: architecture and adr`
- `phase-2: api and db contracts`
- `phase-3: bootstrap and implementation`
- `phase-4: tests and verify`
- `phase-5: final review and gate`

Checkpoint commits use `./scripts/phase-commit.sh`. The template does not run `git push` automatically.

## Expected output after the first multi-agent run

A minimally reasonable first run should leave not only a summary, but also file artifacts:

- `docs/architecture.md` with `Status != template`
- at least one `docs/adr/ADR-*.md`
- `openapi.yaml` with `x-template-status != template`
- `openapi.yaml` generated from TZ requirements (not health-only unless TZ scope is system-only)
- `docs/schema-decisions.md` with `Status != template`
- `docs/dev-environment.md` with `Status != template`
- `docs/test-matrix.md` with `Status != template`
- `docs/final-review.md` with `Status != template`
- `.env.example` and a basic settings/bootstrap layer if foundation was missing before the run

In addition to docs, there must be real backend changes in at least one area:

- runtime code
- migrations
- tests

If a contract conflict appears during the run, an explicit Change Request is also an acceptable artifact; silent divergence between API and DB is not.

## Default phase artifacts

- `docs/architecture.md`: Phase 1, owned by `Architect`.
- `docs/adr/ADR-*.md`: Phase 1, owned by `Architect`.
- `openapi.yaml`: Phase 2, owned by `API`.
- `docs/dev-environment.md`: Phase 3, owned by `Devenv`.
- `docs/schema-decisions.md`: Phase 2, owned by `DB`.
- `docs/test-matrix.md`: Phase 4, owned by `Tests`.
- `docs/final-review.md`: Phase 5, owned by `Gatekeeper`.

Phase completion rules:

- The Markdown artifact must exist and must be updated out of template state (`Status:` is not `template`).
- `openapi.yaml` must exist and must be updated out of template state (`x-template-status:` is not `template`).
- Required in-scope TZ requirements must map to OpenAPI operations implemented in runtime code and covered by tests; deferred operations require explicit out-of-scope justification.
- Orchestrator validates phases by files and status markers, not by agent summaries.

## Interaction rules

1. API/DB/Architecture contracts do not change without a Change Request.
2. DB does not change API contracts directly.
3. API does not change the DB schema directly.
4. Devenv owns startup commands, env bootstrap, and local services/API.
5. Worker does not override architecture decisions.
6. Security Reviewer, Consistency Reviewer, Performance Reviewer, Explorer, and Monitor run read-only.
7. Gatekeeper aggregates review findings and publishes the single final gate decision.
8. Conflicting decisions must be recorded explicitly and routed through Orchestrator.

## Change Request protocol

If a change affects a contract:

1. Record:
   - what changes;
   - why the current state blocks progress;
   - impact on API/DB/tests/release.
2. Hand the CR to Orchestrator.
3. Orchestrator decides update ordering and owners.

## Acceptance conditions (Definition of Done)

The project is considered ready when:

- all target endpoints of the current API version are implemented;
- all in-scope TZ requirements are mapped to OpenAPI operations and implemented;
- RBAC/ownership and critical negative scenarios are covered by tests;
- migrations apply to a clean DB;
- idempotency of critical mutation endpoints is confirmed by tests;
- logs/metrics are present and there are minimal health checks;
- local dev environment and API start reproducibly;
- `.env.example` exists and secrets are neither hardcoded nor committed in `.env`;
- the error layer uses a unified app-level contract with safe public messages;
- the `Service` / `Repository` boundary is respected and transactions are owned by service/UoW;
- `project-stack.toml` matches the real project stack and entrypoints (template defaults are valid if unchanged);
- default phase artifacts are updated: `docs/architecture.md`, `docs/adr/ADR-*.md`, `openapi.yaml`, `docs/dev-environment.md`, `docs/schema-decisions.md`, `docs/test-matrix.md`, `docs/final-review.md`;
- backend changes exist in source and/or migrations and/or tests (not only docs/.codex);
- `./scripts/verify.sh` exits with code `0`;
- Gatekeeper reports no blocker issues after review.

## What a bad run looks like

A bad run for this template usually looks like:

- only `docs/`, `.codex/`, or the spec changed, but no runtime code, migrations, or tests changed;
- phase artifacts are still in template state (`Status: template` or `x-template-status: template`);
- `openapi.yaml` remains health-only while the spec requires business API modules;
- `project-stack.toml` does not match the real project and agents operate on wrong assumptions;
- `.env.example` is missing and secrets/local settings are spread across code or committed in `.env`;
- services and repositories mixed responsibilities: business logic moved into repositories or transactions do `commit` / `rollback` outside service/UoW;
- API returns raw library exceptions, internal-layer `HTTPException`, or messages containing PII/secrets;
- Orchestrator stops at a summary even though `verify` is not green or Gatekeeper has blocker findings;
- API and DB diverge without an explicit Change Request;
- tests/verify require a running stack but Devenv was not used;
- the first run did not leave reproducible startup/verify guidance for the next iteration.

## Running via `run.sh`

The project root includes `run.sh` for standard runs.

Verification:

```bash
./run.sh
./run.sh verify
```

Multi-agent Codex run:

```bash
./run.sh codex
./run.sh codex backend_tz_from_template.md
./run.sh codex-auto backend_tz_from_template.md
./run.sh codex-danger backend_tz_from_template.md
```

Help:

```bash
./run.sh help
```

Requirements for `./run.sh codex`:

- `codex` is available in `PATH`;
- `~/.codex/config.toml` may contain a `multi_agent_backend` profile (or the profile in `CODEX_MULTI_AGENT_PROFILE`);
- if no profile is found, `run.sh` runs without `--profile` and prints a warning;
- if your `codex` supports the `multi_agent` feature flag, `run.sh` enables it automatically.

Minimum recommended profile:

```toml
[profiles.multi_agent_backend]
approval_policy = "never"
sandbox_mode = "danger-full-access"
```

Run modes:

- `./run.sh codex ...`: uses `multi_agent_backend` profile if found, otherwise falls back to `--ask-for-approval never --sandbox danger-full-access`.
- `./run.sh codex-auto ...`: uses profile when available and forces `--full-auto` (works without profile too).
- `./run.sh codex-danger ...`: uses profile when available and forces `--dangerously-bypass-approvals-and-sandbox` (works without profile too).

## How to test

Base verify entrypoint:

```bash
./run.sh verify
```

Direct verify script:

```bash
./scripts/verify.sh
```

Alternative entrypoints (if supported by the project):

```bash
make verify
task verify
```
