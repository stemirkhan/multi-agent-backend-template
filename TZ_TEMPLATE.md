# Project Spec: <PROJECT_NAME>
Version: <v1.0>
Date: <YYYY-MM-DD>
Owner: <NAME/TEAM>

## 0. Stack Profile
Machine-readable source of truth: `project-stack.toml`

This section must stay synchronized with `project-stack.toml`.

- Language/framework: `python` + `fastapi`
- Schemas/validation: `Pydantic`
- Persistence/migrations: `SQLAlchemy` + `Alembic`
- DI: `dishka`
- Messaging: `faststream` + `redis` / `redis-streams`
- Cache/DB: `redis` + `postgres`
- Dev containers: `podman` + `podman-compose`
- API runtime: `uvicorn` -> `app.main:app`
- Verify entrypoint: `./scripts/verify.sh`

## 1. Goal And Scope
### 1.1 MVP Goal
- <Measurable business outcome 1>
- <Measurable business outcome 2>

### 1.2 In Scope
- <What is definitely in MVP>

### 1.3 Out of Scope
- <What we are not doing in MVP>

## 2. Business Scenarios
### US-001: <Scenario Name>
- Actor: <who>
- Preconditions: <what must be true before start>
- Steps: <briefly>
- Result: <expected result>

### US-002: <Scenario Name>
- Actor: <who>
- Preconditions: <...>
- Steps: <...>
- Result: <...>

## 3. Glossary
- <Term 1>: <definition>
- <Term 2>: <definition>

## 4. Functional Requirements (FR)
- FR-001: <requirement>, input: <...>, output: <...>, constraints: <...>
- FR-002: <requirement>, input: <...>, output: <...>, constraints: <...>

## 5. Non-Functional Requirements (NFR)
- NFR-001 (Performance): <p95/p99, SLA/SLO>
- NFR-002 (Security): <auth, RBAC, ownership, secrets>
- NFR-003 (Reliability): <retry, timeout, idempotency>
- NFR-004 (Observability): <logs, metrics, alerts, tracing>

### 5.1 Bootstrap and Code Conventions
- Settings/env: `pydantic-settings`, `.env` is not committed, `.env.example` is required
- Error model: one unified `AppError`-style contract with `code`, `message`, `details`
- Service/Repository boundary: business logic and transactions live in services/UoW, repositories do not do `commit` / `rollback`
- Public typing: public interfaces are typed

## 6. Architectural Decisions (ADR-ready)
- Queues/background jobs: <description>
- Cache: keys, TTL, invalidation: <description>
- Security boundaries: <ownership boundary>
- Transaction boundaries: <where atomicity is mandatory>

## 7. DB Contract
### 7.1 Entities
- <Entity>: fields (<type>, nullable, default), PK/FK, constraints

### 7.2 Indexes
- IDX-001: <table/fields>, for query: <which one>
- IDX-002: <table/fields>, for sorting: <which one>

### 7.3 Data Policies
- Soft delete: <yes/no, how>
- created_at/updated_at: <rule>
- Migrations: forward-only, no edits to applied revisions

## 8. API Contract v1
`openapi.yaml` is generated/replaced in Phase 2 based on this TZ.

### 8.1 Business API scope (input for API agent)
- Module: `<auth|catalog|salons|masters|services|subscriptions|analytics|admin>`
- Required capability: `<what user must be able to do>`
- Access rule: `<role/ownership>`
- Constraints: `<validation/idempotency/pagination/sorting>`
- Notes: `<anything domain-specific>`

### 8.2 Required operation inventory
- This table may be completed by API agent in Phase 2.
- OP-001: `<operationId>`, endpoint: `METHOD /api/v1/...`, source requirement: `<FR/US id>`, status: `<in_scope|deferred>`, defer reason: `<if deferred>`
- OP-002: `<operationId>`, endpoint: `METHOD /api/v1/...`, source requirement: `<FR/US id>`, status: `<in_scope|deferred>`, defer reason: `<if deferred>`
- Rule: every in-scope FR/US must map to one or more operations.
- Rule: deferred operations are allowed only with explicit rationale in section 1.3 Out of Scope.

### 8.3 Idempotency matrix
- `POST /...`: Idempotency-Key <required|optional>, scope: <...>, TTL: <...>
- `POST /...`: Idempotency-Key <required|optional>, scope: <...>, TTL: <...>

## 9. RBAC And Ownership Matrix
- Role `<role_a>`: allow `<endpoint_list>`, deny `<endpoint_list>`
- Role `<role_b>`: allow `<endpoint_list>`, deny `<endpoint_list>`
- Ownership rule: `<entity_owner_id == user_id>`

## 10. Integrations And Events
- Event: `<name>`, producer: `<service>`, consumer: `<service>`, payload: `<schema>`
- Retry/DLQ policy: <description>

## 11. Test Strategy
- Unit: <key checks>
- Integration: <API + DB + cache/queue>
- Contract: <OpenAPI/error format/idempotency>
- Security: <RBAC/ownership/negative tests>
- Acceptance: <E2E criteria>

## 12. Release Plan
- Rollout steps: <1..N>
- Rollback conditions: <when we roll back>
- Rollback steps: <how we roll back>
- Data backfill (if needed): <how and when>

## 13. Acceptance checklist (Definition of Done)
- [ ] All FRs are completed
- [ ] NFRs are confirmed by metrics/tests
- [ ] Migrations apply to a clean DB
- [ ] All in-scope operations from section 8.2 exist in `openapi.yaml` with stable operationId
- [ ] All in-scope operations from `openapi.yaml` are implemented in runtime routers/services (not health-only baseline)
- [ ] Every in-scope operation has test coverage (at least one success and one negative/auth case)
- [ ] `docs/test-matrix.md` contains operation coverage mapping: TZ requirement -> operationId -> test cases
- [ ] RBAC/ownership is covered by tests
- [ ] Idempotency is confirmed by tests
- [ ] Local dev environment and API start reproducibly
- [ ] `.env.example` is present, and secrets are neither committed nor hardcoded
- [ ] Unified error contract and safe public messages are enforced
- [ ] `Service` / `Repository` boundary is respected, transactions are not controlled from repositories
- [ ] `project-stack.toml` matches the real project stack and entrypoints
- [ ] Phase artifacts are updated: `docs/architecture.md`, `docs/adr/ADR-*.md`, `openapi.yaml`, `docs/dev-environment.md`, `docs/schema-decisions.md`, `docs/test-matrix.md`, `docs/final-review.md`
- [ ] `./scripts/verify.sh` exits with code 0

## 14. Ownership By Agent
- Architect: owns sections 5/6, `docs/architecture.md`, and architectural ADRs in `docs/adr/`
- DB: owns section 7, the SQLAlchemy/Alembic layer, and `docs/schema-decisions.md`
- API: owns section 8, the FastAPI/Pydantic contract, and `openapi.yaml`
- Devenv: local FastAPI runtime/bootstrap, `docs/dev-environment.md`
- Worker: FastAPI backend implementation against the contracts
- Tests: strategy and FastAPI backend tests from section 11, `docs/test-matrix.md`
- Security Reviewer: access control, ownership, auth/rbac, secret leakage review
- Consistency Reviewer: idempotency, transactions, races, duplicate side effects review
- Performance Reviewer: N+1, indexes, heavy sorts, query shape review
- Gatekeeper: aggregates review findings and owns `docs/final-review.md`
- Monitor: runs verify and summarizes results

## 15. Default Phase Artifacts
- Phase 1: `docs/architecture.md`, `docs/adr/ADR-*.md`
- Phase 2: `openapi.yaml`, `docs/schema-decisions.md`
- Phase 3: `docs/dev-environment.md`
- Phase 4: `docs/test-matrix.md`
- Phase 5: `docs/final-review.md`
- Markdown artifacts must update `Status:` from `template` to a working value.
- `openapi.yaml` must update `x-template-status:` from `template` to a working value.

## 16. Change Request Protocol
- What changes: <contract/rule/field/endpoint>
- Why: <blocker/incompatibility>
- Impact: <API/DB/tests/rollout>
- Compatibility: <backward-compatible yes/no/partial>
- Verification plan: <which checks must pass>
- Owner and next step: <who does what>
