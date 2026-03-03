# ADR-20260301-spec-driven-operation-completeness-gate

## ADR ID
`ADR-20260301-spec-driven-operation-completeness-gate`

## Status
`accepted`

## Context
- The existing multi-agent phase loop can close successfully on a runtime bootstrap skeleton (healthcheck + basic artifacts) even when the task spec describes full business MVP functionality.
- This creates a mismatch between user expectations ("implement full REST API from spec/OpenAPI") and workflow completion criteria.
- `openapi.yaml` and the task spec must become execution contracts, not documentation-only outputs.
- We need deterministic closure criteria that force implementation and test coverage for all required operations.

## Decision
- Adopt a spec-driven operation completeness gate across Orchestrator/API/Gatekeeper instructions and runtime prompt.
- Define required operation as each OpenAPI `path + method`, unless explicitly deferred with `x-implementation-status: deferred` and out-of-scope justification in the task spec.
- Do not allow Phase 2 completion when business requirements imply endpoints missing from OpenAPI.
- Do not allow workflow completion when required operations lack runtime implementation and test coverage evidence.
- Require operation coverage mapping (`operationId -> tests`) in `docs/test-matrix.md`.

## Alternatives Considered
1. `bootstrap-first closure` (current behavior): fast first pass, but can falsely report completion while business API is not implemented.
2. `manual user checklist only`: flexible, but too easy to drift; no deterministic enforcement across agents.
3. `spec-driven operation completeness gate` (chosen): strict and predictable; aligns phase closure with actual delivery scope.

## Consequences
- Positive outcomes:
  - Workflow closes only when in-scope API surface is actually delivered.
  - OpenAPI becomes actionable contract for implementation and tests.
  - Gatekeeper has explicit blocker criteria for missing operations.
- Negative outcomes and debt:
  - More up-front contract work in Phase 2.
  - Legacy template runs that rely on minimal skeleton behavior may require stricter task specs or explicit deferrals.

## Contract Impact
- API impact:
  - API agent must maintain operation inventory completeness and defer markers.
  - Health-only contract is insufficient for business specs.
- DB impact:
  - DB contract must evolve with mutating endpoint requirements before implementation.
- Worker/tests/monitor impact:
  - Worker must implement all required operations.
  - Tests must provide operation-level evidence in `docs/test-matrix.md`.
  - Gatekeeper must treat missing operation coverage as blocker.

## Rollout Plan
1. `orchestrator`: update `.codex/agents/orchestrator.toml` and `run.sh` prompt with operation completeness rules.
2. `api`: update `.codex/agents/api.toml` to enforce operation inventory and deferral policy.
3. `gatekeeper`: update `.codex/agents/gatekeeper.toml` with operation-coverage blocker policy.
4. `template`: update `TZ_TEMPLATE.md` and `README.md` to require operation inventory and coverage evidence.

## Rollback Plan
- Trigger condition:
  - The stricter gate blocks bootstrap-only onboarding workflows where full business API implementation is intentionally postponed.
- Safe rollback steps:
  - Revert operation completeness requirements in `run.sh` and agent instructions.
  - Keep only minimal runtime-change requirement for initial bootstrap passes.

## Verification
- Checks/tests required:
  - `pytest -q` (or the repository's current test/check entrypoint)
  - Manual prompt inspection: `run.sh` includes required operation completeness conditions.
  - Agent config inspection: orchestrator/api/gatekeeper include operation completeness rules.
  - Template inspection: `TZ_TEMPLATE.md` acceptance checklist requires operation coverage.
- Expected check result (`exit code 0`).

## Open Questions
- Should we add an explicit machine-readable `operation inventory` artifact (for example `docs/operation-matrix.md`) instead of relying on `docs/test-matrix.md` only?
