# ADR-20260301-bound-phase5-review-loop

## ADR ID
`ADR-20260301-bound-phase5-review-loop`

## Status
`accepted`

## Context
- Phase 5 can currently automatically rerun review after blocker findings.
- In practice, findings often require non-trivial changes: new CRs, runtime code changes, migrations, and tests.
- Without a hard limit, the remediation loop turns review into an open-ended implementation phase, burns model budget, and stretches completion into hours.
- The template needs a predictable stop condition without losing a single final gate through `Gatekeeper`.

## Decision
- Bound Phase 5 to a hard loop: one full review pass, at most one remediation pass, and one targeted re-review.
- The full review pass runs as before: `security-reviewer`, `consistency-reviewer`, and `performance-reviewer` in parallel, then `Gatekeeper`.
- After fixing blockers, rerun only the review domains affected by blocker findings, and only for changed files/flows, not the entire repository.
- If after remediation `verify` is green and `Gatekeeper` returns `pass`, close Phase 5 immediately with a checkpoint commit and do not start another review cycle.
- If a blocker remains after the targeted re-review, stop the automation loop and have Orchestrator return unresolved blockers to the user/next owner instead of automatically repeating again.

## Alternatives Considered
1. `unbounded review loop`: maximally autonomous, but expensive, unpredictable in time, and can endlessly drift into new implementation work.
2. `bounded loop with targeted re-review`: chosen option; keeps automation but bounds cost/time, and keeps reruns scoped to the blocker diff.
3. `single review pass with no remediation`: cheap and simple, but too often leaves the user with findings and no automated fix attempt.

## Consequences
- Positive outcomes:
  - Phase 5 becomes predictable in duration and cost.
  - Review stays focused on the blocker diff instead of rescanning the full project.
  - `Gatekeeper` remains the single final decision point.
- Negative outcomes and debt:
  - Some blockers will require a manual workflow restart after the bounded loop stops.
  - Orchestrator prompts must remain disciplined to avoid expanding targeted reruns back into full review.

## Contract Impact
- API impact:
  - The public API contract does not change.
- DB impact:
  - The DB contract does not change.
- Worker/tests/monitor impact:
  - `Orchestrator` and `run.sh` must enforce the bounded Phase 5 policy.
  - Review reruns must be scoped by blocker diff and affected domains.

## Rollout Plan
1. `orchestrator`: update Phase 5 rules and stop rules in `.codex/agents/orchestrator.toml`.
2. `run.sh`: synchronize the runtime prompt with the bounded Phase 5 policy.

## Rollback Plan
- Trigger condition:
  - The bounded loop systematically misses critical findings that were previously caught by repeated full review passes.
- Safe rollback steps:
  - Restore the unbounded Phase 5 policy in `orchestrator.toml` and `run.sh`.
  - Keep the review roles and `Gatekeeper` unchanged.

## Verification
- Checks/tests required:
  - `./scripts/verify.sh`
  - Check that `orchestrator.toml` and `run.sh` describe the same bounded Phase 5 policy.
- Expected verify result (`exit code 0`).

## Open Questions
- Do we want an explicit machine-readable marker for Phase 5 rerun budget so Monitor can validate policy beyond prompt text?
