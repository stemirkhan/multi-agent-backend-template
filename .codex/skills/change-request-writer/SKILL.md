---
name: change-request-writer
description: Write clear contract change requests with impact analysis for API, DB, and architecture decisions. Use when an agent cannot proceed without changing an existing contract, when API and DB become incompatible, or when orchestrator needs a standardized CR for routing and approval.
---

# Change Request Writer

## Overview

Produce a compact, decision-ready CR that orchestrator can route and DB/API can execute without follow-up clarification.

## Workflow

1. Confirm trigger
- Continue only when a contract change is required (API, DB, Architect).
- If no contract change is needed, stop and return a brief "No CR needed" explanation.

2. Gather minimum context
- Current behavior and blocking point.
- Requested change at schema/contract level.
- Which agents are impacted (`api`, `db`, `architect`, `tests`, `worker`).

3. Draft CR using the template
- Use [`references/cr-template.md`](references/cr-template.md).
- Fill all required fields with concise, testable statements.
- Prefer concrete fields/types/endpoints over abstract language.

4. Add compatibility and rollout notes
- State backward-compatibility status explicitly.
- List migration/test implications.
- Specify follow-up sequence for orchestrator.

## Output Rules

- Keep CR actionable and short.
- Include exact artifacts to change (files/tables/endpoints).
- Include acceptance criteria with observable outcomes.
- Avoid implementation details that belong to worker code.

## Quality Checklist

- Is the problem blocking and contract-level?
- Is requested change unambiguous?
- Is impact on API/DB/Tests explicit?
- Is rollback or mitigation defined when risk is non-trivial?
- Are next owners and order clear for orchestrator?
