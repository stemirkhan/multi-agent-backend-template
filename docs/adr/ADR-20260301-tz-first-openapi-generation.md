# ADR-20260301-tz-first-openapi-generation

## ADR ID
`ADR-20260301-tz-first-openapi-generation`

## Status
`accepted`

## Context
- Users provide a product TZ and expect agents to build contracts and implementation from it.
- A pre-seeded `openapi.yaml` (for example health-only placeholder) can bias agents toward under-implementation.
- The workflow must work when `openapi.yaml` is absent at repository start.
- We need one explicit entry input for product scope: TZ file.

## Decision
- Adopt `TZ-first` orchestration: the TZ file is the primary product contract input.
- In Phase 2, API agent must generate or fully replace `openapi.yaml` from TZ + architecture/DB constraints.
- Pre-existing OpenAPI content is treated as placeholder, not as source-of-truth.
- Template verification must not require pre-seeded `openapi.yaml` before the first run.

## Alternatives Considered
1. Keep pre-seeded OpenAPI as starting source:
   - Pros: simple bootstrap example.
   - Cons: often locks workflow into health-only scope.
2. Remove OpenAPI entirely and rely on runtime inference only:
   - Pros: no placeholder bias.
   - Cons: weaker contract discipline without explicit Phase 2 output.
3. TZ-first + generated OpenAPI artifact (chosen):
   - Pros: single user input, contract-first flow, clear Phase 2 deliverable.
   - Cons: stronger dependency on TZ quality.

## Consequences
- Positive outcomes:
  - User provides only TZ for scope definition.
  - Agents derive operation inventory from TZ and produce OpenAPI as artifact.
  - Placeholder OpenAPI no longer blocks full-feature delivery.
- Negative outcomes and debt:
  - Poorly structured TZ can still produce incomplete contracts.
  - Requires stricter API/orchestrator validation of TZ-to-operation mapping.

## Contract Impact
- API impact:
  - API agent must generate/replace OpenAPI in Phase 2 from TZ.
- DB impact:
  - DB decisions must align with TZ-derived operation scope and mutating endpoints.
- Worker/tests/monitor impact:
  - Worker and Tests consume generated OpenAPI, not seed placeholders.
  - Gatekeeper verifies TZ requirement -> operation -> test coverage chain.

## Rollout Plan
1. Update `run.sh` prompt to enforce TZ-first contract generation.
2. Update orchestrator/api/gatekeeper/tests agent instructions to use TZ-first mapping.
3. Update `scripts/verify.sh` to allow missing pre-seeded `openapi.yaml`.
4. Remove seed `openapi.yaml` from template root.
5. Update README and TZ template guidance.

## Rollback Plan
- Trigger condition:
  - Teams need a permanent pre-seeded OpenAPI for template demos/training.
- Safe rollback steps:
  - Restore seed `openapi.yaml`.
  - Re-enable strict verify check for pre-seeded OpenAPI presence.
  - Keep TZ-first mapping rules for real runs, if desired.

## Verification
- Checks/tests required:
  - `./scripts/verify.sh` passes without root `openapi.yaml`.
  - `run.sh` prompt states TZ-first and Phase 2 OpenAPI generation.
  - Agent configs state TZ-first mapping and coverage requirements.
- Expected verify result (`exit code 0`).

## Open Questions
- Do we need a dedicated machine-readable `operation inventory` file in addition to `docs/test-matrix.md`?
