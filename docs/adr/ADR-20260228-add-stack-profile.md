# ADR-20260228-add-stack-profile

## ADR ID
`ADR-20260228-add-stack-profile`

## Status
`accepted`

## Context
- The template is already fixed to a FastAPI stack, but the technology expectations were previously scattered across README, spec, prompts, and agent instructions.
- As a result, agents had to infer framework/runtime/tooling from prose instead of reading one machine-readable contract.
- For Devenv, Worker, Tests, and Monitor, accurate fields for runtime, DI, messaging, and containers are especially important.

## Decision
- Add `project-stack.toml` at the repository root as the project's machine-readable stack profile.
- Make `project-stack.toml` the source of truth for `language`, `framework`, `orm`, `migration_tool`, `test_runner`, `di_library`, `message_framework`, `message_broker`, `message_transport`, `cache`, `db`, `container_runtime`, `compose_tool`, `api_runner`, and `api_entrypoint`.
- Require Orchestrator and runtime-oriented agents to read `project-stack.toml` first, and only then use README/spec as explanatory context.

## Alternatives Considered
1. `STACK.md`: easier for humans to read, but worse for automated checks and agent usage.
2. `project-stack.toml`: chosen option; easy to parse, validate, and use as a source of truth.
3. `hardcoded prompts only`: fewer files, but the stack remains scattered and harder to maintain.

## Consequences
- Positive outcomes:
  - Agents get one machine-readable contract for the stack and entrypoints.
  - Template checks can validate presence and basic correctness of the stack profile.
  - README and the spec remain human-readable, but stop being the only stack source.
- Negative outcomes and debt:
  - `project-stack.toml` must be kept up to date manually.
  - If the template expands to other stacks, the schema and agent instructions must be updated.

## Contract Impact
- API impact:
  - The API Agent stops guessing framework/runtime assumptions and reads them from `project-stack.toml`.
- DB impact:
  - The DB Agent gets an explicit profile for ORM/migration/db/cache assumptions.
- Worker/tests/monitor impact:
  - Devenv, Worker, Tests, and Monitor rely on the stack profile for runtime, DI, messaging, and containers.

## Rollout Plan
1. `template`: add `project-stack.toml` with the default FastAPI profile.
2. `orchestrator/docs`: synchronize prompts, agent instructions, and template checks.

## Rollback Plan
- Trigger condition:
  - The stack profile is not used by agents in practice, or it creates more drift than value.
- Safe rollback steps:
  - Remove `project-stack.toml`.
  - Revert to textual stack assumptions as the only source.
  - Remove the stack profile from checks and agent instructions.

## Verification
- Checks/tests required:
  - `pytest -q` (or the repository's current test/check entrypoint)
  - Check that `project-stack.toml` exists, parses, and contains required fields.
  - Check that docs/prompts reference the stack profile as the source of truth.
- Expected check result (`exit code 0`).

## Open Questions
- Do we need a future schema version with nested sections instead of flat keys?
