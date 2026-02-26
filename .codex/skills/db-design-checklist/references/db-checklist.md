# DB Design Checklist

## Scope
- [ ] Change scope is explicit (tables, columns, indexes, constraints).
- [ ] Related API fields/endpoints are mapped.

## Schema
- [ ] Types are correct and minimal.
- [ ] `NULL/NOT NULL` is justified.
- [ ] Defaults are explicit and safe.
- [ ] FK constraints are explicit.
- [ ] UNIQUE/CHECK constraints are explicit.
- [ ] Enum reuse is consistent.

## Data Policy
- [ ] `created_at` and `updated_at` present.
- [ ] Soft delete (`deleted_at`) behavior defined.
- [ ] Partial unique logic accounts for soft delete.
- [ ] Money model uses `price_minor` + `currency`.

## Indexing
- [ ] Indexes map to real filter/sort/query patterns.
- [ ] Heavy sorts have supporting indexes or documented limitation.
- [ ] Write amplification risk is acceptable.

## Migration Safety
- [ ] Migration is forward-only.
- [ ] No edit of already-applied migration.
- [ ] Backfill strategy defined when needed.
- [ ] Lock/risk profile documented.

## Compatibility and Validation
- [ ] Backward compatibility state recorded (`yes|no|partial`).
- [ ] Breaking/ambiguous changes escalated via CR.
- [ ] Tests to update are listed.
- [ ] Verify target: `./scripts/verify.sh` exits with code `0`.
