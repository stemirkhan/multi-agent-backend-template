# Architecture Contract
Status: template
Owner: Architect
Phase: 1

Этот файл обязателен для Phase 1.
Перед закрытием фазы замени шаблонные пункты на реальные решения и обнови `Status:`.

## 1. System Scope
- Product/domain:
- MVP boundaries:
- External dependencies:

## 2. Module Boundaries
- API layer:
- Application/services:
- Persistence:
- Background workers:

## 3. Data Flow
- Write path:
- Read path:
- Event flow:

## 4. Cache And Queue Decisions
- Cache keys / TTL / invalidation:
- Queue / stream choice:
- Retry / failure handling:

## 5. Transaction Boundaries
- What must be atomic:
- What is eventually consistent:
- Idempotency assumptions:

## 6. Security Boundaries
- Authentication:
- RBAC:
- Ownership boundary:
- Secret handling:

## 7. Observability
- Logs:
- Metrics:
- Health checks:

## 8. Risks And Open Questions
- Risk:
- Open question:
