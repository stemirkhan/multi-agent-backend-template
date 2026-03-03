# ADR-20260228-split-review-roles

## ADR ID
`ADR-20260228-split-review-roles`

## Status
`accepted`

## Context
- The template used to have a single `Reviewer` role that checked security, consistency, and performance/data-access risks at the same time.
- That reviewer was overloaded and mixed multiple review disciplines in one agent.
- Phase 5 needs parallelization across independent risk domains without losing a single final gate.

## Decision
- Split the review layer into `security-reviewer`, `consistency-reviewer`, `performance-reviewer`, and `gatekeeper`.
- Specialized review agents run in read-only mode and return findings only for their domain.
- `Gatekeeper` does not perform a deep independent audit; it aggregates findings, publishes the final gate, and writes `docs/final-review.md`.

## Alternatives Considered
1. `single reviewer`: simpler orchestration, but one role is overloaded and parallelization is poor.
2. `three reviewers + gatekeeper`: chosen option; separates by risk domain and preserves a single final gate.
3. `more granular reviewers`: higher precision per area, but orchestration becomes heavier and harder to maintain.

## Consequences
- Positive outcomes:
  - Phase 5 can now be parallelized across independent risk areas.
  - The final pass/fail decision remains single through `Gatekeeper`.
  - Review prompts become narrower and clearer by ownership.
- Negative outcomes and debt:
  - The number of agent roles and related documentation increases.
  - Orchestration discipline is required: Gatekeeper must run only after specialized review agents.

## Contract Impact
- API impact:
  - No change to the public API contract.
- DB impact:
  - No change to the DB contract.
- Worker/tests/monitor impact:
  - `Orchestrator` must run review agents in parallel and then run `Gatekeeper` separately.
  - `run.sh`, `README`, `TZ_TEMPLATE.md`, and the detailed guide must reference `Gatekeeper`, not a single `Reviewer`.

## Rollout Plan
1. `orchestrator`: replace the monolithic reviewer with four roles and update Phase 5.
2. `docs/config`: synchronize the registry, required agents, ownership, and the final review artifact.

## Rollback Plan
- Trigger condition:
  - Orchestration complexity becomes too high or the final gate becomes unstable.
- Safe rollback steps:
  - Revert to a single `Reviewer`.
  - Remove specialized review agents from the registry and docs.
  - Keep `docs/final-review.md` as the single final-review artifact.

## Verification
- Checks/tests required:
  - `pytest -q` (or the repository's current test/check entrypoint)
  - Check that required agents include three review agents and `Gatekeeper`.
  - Check that docs and prompts use `Gatekeeper` as the final source of truth.
- Expected check result (`exit code 0`).

## Open Questions
- Do we want separate `docs/reviews/*.md` artifacts in the future for per-reviewer traceability?
