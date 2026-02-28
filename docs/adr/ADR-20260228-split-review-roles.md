# ADR-20260228-split-review-roles

## ADR ID
`ADR-20260228-split-review-roles`

## Status
`accepted`

## Context
- В шаблоне был один `Reviewer`, который одновременно проверял security, consistency и performance/data-access риски.
- Такой reviewer был перегружен по области ответственности и смешивал несколько разных дисциплин review в одном агенте.
- Phase 5 нужна параллелизация по независимым risk domains без потери единого финального gate.

## Decision
- Разделить review слой на `security-reviewer`, `consistency-reviewer`, `performance-reviewer` и `gatekeeper`.
- Специализированные review-агенты работают read-only и возвращают findings только по своей области.
- `Gatekeeper` не проводит глубокий самостоятельный аудит, а агрегирует findings, ставит финальный gate и пишет `docs/final-review.md`.

## Alternatives Considered
1. `single reviewer`: проще orchestration, но одна роль перегружена и хуже параллелится.
2. `three reviewers + gatekeeper`: выбранный вариант; дает разделение по risk domain и сохраняет единый финальный gate.
3. `more granular reviewers`: выше точность по областям, но orchestration становится тяжелее и сложнее в сопровождении для шаблона.

## Consequences
- Positive outcomes:
  - Phase 5 теперь параллелится по независимым областям риска.
  - Финальное решение по pass/fail остается единым через `Gatekeeper`.
  - Review prompts становятся уже и понятнее по ownership.
- Negative outcomes and debt:
  - Увеличивается количество агентных ролей и связанной документации.
  - Нужна дисциплина orchestration: Gatekeeper должен запускаться только после специализированных review-агентов.

## Contract Impact
- API impact:
  - Нет изменения публичного API-контракта.
- DB impact:
  - Нет изменения DB-контракта.
- Worker/tests/monitor impact:
  - `Orchestrator` должен запускать review-агентов параллельно и затем отдельно `Gatekeeper`.
  - `run.sh`, `README`, `TZ_TEMPLATE.md` и подробный guide должны ссылаться на `Gatekeeper`, а не на одиночного `Reviewer`.

## Rollout Plan
1. `orchestrator`: заменить монолитного reviewer на четыре роли и обновить Phase 5.
2. `docs/config/verify`: синхронизировать registry, required agents, ownership и final review artifact.

## Rollback Plan
- Trigger condition:
  - Слишком высокая сложность orchestration или нестабильность финального gate.
- Safe rollback steps:
  - Вернуть единый `Reviewer`.
  - Удалить специализированные review-агенты из registry и docs.
  - Оставить `docs/final-review.md` как единый артефакт финального review.

## Verification
- Checks/tests required:
  - `./scripts/verify.sh`
  - Проверка, что required agents включают три review-агента и `Gatekeeper`.
  - Проверка, что docs и prompts используют `Gatekeeper` как финальный source of truth.
- Expected verify result (`exit code 0`).

## Open Questions
- Нужно ли в будущем добавлять отдельные артефакты `docs/reviews/*.md` для traceability по каждому reviewer.
