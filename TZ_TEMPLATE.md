# Project Spec (TZ): <PROJECT_NAME>
Version: <v1.0>
Date: <YYYY-MM-DD>
Owner: <NAME/TEAM>

## 0. Stack Profile
Machine-readable source of truth: `project-stack.toml`

Default stack:
- Language/framework: `python` + `fastapi`
- Persistence/migrations: `sqlalchemy` + `alembic`
- DI: `dishka`
- Messaging: `faststream` + `redis-streams`
- Cache/DB: `redis` + `postgres`
- API runtime: `uvicorn` -> `app.main:app`

## 1. Goal And Scope
### 1.1 MVP Goal
- <Measurable business outcome 1>
- <Measurable business outcome 2>

### 1.2 In Scope
- <What is in MVP>

### 1.3 Out of Scope
- <What is explicitly out>

## 2. Business Scenarios (US)
### US-001: <Scenario Name>
- Actor: <who>
- Preconditions: <what must be true>
- Steps: <briefly>
- Result: <expected>

### US-002: <Scenario Name>
- Actor: <who>
- Preconditions: <...>
- Steps: <...>
- Result: <...>

## 3. Functional Requirements (FR)
- FR-001: <requirement>, input: <...>, output: <...>
- FR-002: <requirement>, input: <...>, output: <...>

## 4. Non-Functional Requirements (NFR)
- NFR-001 Performance: <p95/p99, SLA/SLO>
- NFR-002 Security: <auth/RBAC/ownership/secrets>
- NFR-003 Reliability: <timeouts/retries/idempotency>
- NFR-004 Observability: <logs/metrics/alerts>

## 5. API Contract Input
`openapi.yaml` is generated/replaced from this TZ.

### 5.1 Required operation inventory
- OP-001: `<operationId>`, endpoint: `METHOD /api/v1/...`, source: `<FR/US id>`, status: `<in_scope|deferred>`
- OP-002: `<operationId>`, endpoint: `METHOD /api/v1/...`, source: `<FR/US id>`, status: `<in_scope|deferred>`

Rules:
- every in-scope FR/US maps to one or more operationIds
- deferred operations must be justified in section 1.3

## 6. DB Contract Input (high-level)
- Entities and key relations: <list>
- Constraints/indexes: <list>
- Data policies (soft-delete/timestamps): <list>

## 7. Test Strategy
- Unit: <key checks>
- Integration: <API + DB>
- Contract: <OpenAPI + error codes>
- Security: <RBAC/ownership negative tests>

## 8. Acceptance Checklist (DoD)
- [ ] All in-scope FR/US mapped to operationIds
- [ ] `openapi.yaml` generated/updated with stable operationIds
- [ ] Required operations implemented in runtime handlers
- [ ] Tests include success + negative/auth for required operations
- [ ] `./scripts/check.sh` exits with code 0
- [ ] Backend changes are not docs-only
- [ ] `docs/final-review.md` updated with explicit pass/fail and blockers

## 9. Ownership By Agent (Simplified)
- `api`: OpenAPI and operation inventory
- `worker`: runtime implementation
- `tests`: coverage + check execution
- `gatekeeper`: final pass/fail decision
- `orchestrator`: sequencing and blocker routing

## 10. Phase Artifacts (Simplified)
- Phase 1 (`contracts`): `openapi.yaml`
- Phase 2 (`implementation`): runtime code/migrations
- Phase 3 (`validation+gate`): tests + `docs/final-review.md`
