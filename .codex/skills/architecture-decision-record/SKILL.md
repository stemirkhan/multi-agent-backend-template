---
name: architecture-decision-record
description: Create architecture decision records (ADR) with alternatives, tradeoffs, impact, and rollout/rollback notes. Use when architect, API, DB, or orchestrator must formalize a system-level decision (queue, cache, boundaries, consistency, security, data model policy) before implementation.
---

# Architecture Decision Record

## Overview

Produce consistent ADR documents so orchestration and implementation use the same decision basis.

## Workflow

1. Confirm ADR trigger
- Continue only for architecture-level decisions.
- If task is only implementation detail, stop and report "ADR not required".

2. Capture context and constraints
- Problem statement and system scope.
- Non-functional constraints: consistency, latency, reliability, cost, security, operability.
- Contract touchpoints: API/DB/worker/tests.

3. Evaluate alternatives
- List at least 2 viable options.
- Use objective criteria and explicit tradeoffs.
- Mark rejected options with reasons.

4. Record decision and rollout
- Use [`references/adr-template.md`](references/adr-template.md).
- Write final decision in concrete terms.
- Include rollout, rollback, and verification plan.

## Output Rules

- Keep wording concrete and testable.
- Document impact on contracts and ownership.
- Include risks and mitigation for non-trivial tradeoffs.
- Assign next owners for orchestrator sequencing.

## Quality Checklist

- Is the decision scope truly architectural?
- Are alternatives real and compared with criteria?
- Is compatibility impact explicit?
- Is rollback path defined?
- Is success measurable after rollout?
