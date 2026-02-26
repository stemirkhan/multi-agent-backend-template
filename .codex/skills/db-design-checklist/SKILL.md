---
name: db-design-checklist
description: Design and review database changes with a strict checklist for schema, constraints, indexes, soft delete, migration safety, and API compatibility. Use when DB agent plans new tables/columns/indexes/migrations or validates contract compatibility before implementation.
---

# Db Design Checklist

## Overview

Use a deterministic checklist before accepting DB design changes so migrations remain safe and contracts stay compatible.

## Workflow

1. Capture change intent
- Identify required entity/column/index/constraint changes.
- Map each change to API contract expectations.

2. Run schema checks
- Data types, nullability, defaults.
- FK/UNIQUE/CHECK coverage.
- Enum reuse and naming consistency.
- Money fields as `price_minor` + `currency`.

3. Run operational checks
- Indexes aligned to real filters/sorts.
- Soft delete semantics (`deleted_at`) and partial unique behavior.
- Migration direction: forward-only, no rewrite of applied revisions.

4. Run compatibility checks
- Backward-compatibility status (`yes|no|partial`).
- Required CR when breaking change or ambiguity exists.
- Tests and verify expectations.

5. Produce checklist report
- Use [`references/db-checklist.md`](references/db-checklist.md).
- Mark pass/fail per check and include blocking items.

## Output Rules

- Reject vague changes without query/use-case linkage.
- Prefer explicit constraints over app-level assumptions.
- Include index rationale tied to read/write patterns.
- Include migration rollback risk and mitigation.

## Quality Checklist

- Are all contract-relevant fields explicit?
- Are indexes justified by access patterns?
- Are migration risks documented?
- Are compatibility breaks escalated through CR?
