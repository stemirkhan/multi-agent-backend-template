# Change Request Template

## CR ID
`CR-YYYYMMDD-<slug>`

## Requested By
`<agent>` / `<owner>`

## Contract Area
- `API` | `DB` | `Architect` | multiple

## Problem
- What blocks delivery now.

## Proposed Change
- Exact change request.
- For DB: table/column/type/nullability/default/index/constraint.
- For API: endpoint/schema/field/error-code/status.
- For Architect: rule/policy/decision update.

## Compatibility
- Backward compatible: `yes|no|partial`
- If not fully compatible: migration strategy and deprecation window.

## Impact
- Affected agents: `api`, `db`, `worker`, `tests`, `monitor`, `reviewer`.
- Affected artifacts/files.
- Risk level: `low|medium|high`.

## Verification Plan
- Which tests/checks must pass.
- Expected verify result (`exit code 0`).

## Acceptance Criteria
- Observable outcomes that prove the CR is done.

## Execution Order
1. `<agent>`: `<task>`
2. `<agent>`: `<task>`
3. `<agent>`: `<task>`

## Open Questions
- Clarifications needed for approval.
