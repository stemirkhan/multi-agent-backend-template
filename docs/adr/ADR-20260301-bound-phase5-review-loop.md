# ADR-20260301-bound-phase5-review-loop

## ADR ID
`ADR-20260301-bound-phase5-review-loop`

## Status
`accepted`

## Context
- Phase 5 сейчас умеет автоматически повторять review после blocker-findings.
- На практике review findings часто требуют не косметических правок, а новых CR, runtime-изменений, миграций и тестов.
- Без жёсткого лимита remediation loop превращает review в open-ended implementation phase, расходует лимиты модели и затягивает completion на часы.
- Шаблону нужен предсказуемый stop-condition без потери финального gate через `Gatekeeper`.

## Decision
- Ограничить Phase 5 жёстким циклом: один полный review pass, максимум один remediation pass и один targeted re-review.
- Полный review pass выполняется как и раньше: `security-reviewer`, `consistency-reviewer` и `performance-reviewer` параллельно, затем `Gatekeeper`.
- После blocker-fix rerun'ить только review-домены, затронутые blocker-findings, и только по изменённым файлам/flow, а не по всему репозиторию.
- Если после remediation `verify` зелёный и `Gatekeeper` вернул `pass`, Phase 5 сразу закрывается checkpoint commit'ом без новых review-циклов.
- Если blocker сохраняется после targeted re-review, automation loop останавливается и Orchestrator возвращает unresolved blockers пользователю/следующему владельцу вместо нового автоматического повтора.

## Alternatives Considered
1. `unbounded review loop`: максимально автономно, но дорого, непредсказуемо по времени и может бесконечно перерастать в новую реализацию.
2. `bounded loop with targeted re-review`: выбранный вариант; сохраняет automation, но ограничивает стоимость и время, а rerun держит в рамках blocker diff.
3. `single review pass with no remediation`: дёшево и просто, но слишком часто оставляет пользователя с несведёнными findings без попытки автоматического исправления.

## Consequences
- Positive outcomes:
  - Phase 5 становится предсказуемой по длительности и стоимости.
  - Review остаётся focused на blocker diff, а не пересканирует проект целиком.
  - `Gatekeeper` остаётся единым финальным decision point.
- Negative outcomes and debt:
  - Некоторые blocker'ы потребуют ручного перезапуска workflow после остановки bounded loop.
  - Нужна дисциплина в Orchestrator prompt'ах, чтобы не расширять targeted rerun обратно до полного review.

## Contract Impact
- API impact:
  - Публичный API-контракт не меняется.
- DB impact:
  - DB-контракт не меняется.
- Worker/tests/monitor impact:
  - `Orchestrator` и `run.sh` должны навязывать bounded Phase 5 policy.
  - Review rerun должен быть scoped по blocker diff и affected domains.

## Rollout Plan
1. `orchestrator`: обновить правила Phase 5 и stop-rules в `.codex/agents/orchestrator.toml`.
2. `run.sh`: синхронизировать runtime prompt с bounded Phase 5 policy.

## Rollback Plan
- Trigger condition:
  - Bounded loop системно недобирает критичные findings, которые раньше ловились повторными full review pass.
- Safe rollback steps:
  - Вернуть unbounded Phase 5 policy в `orchestrator.toml` и `run.sh`.
  - Оставить review-роли и `Gatekeeper` без изменений.

## Verification
- Checks/tests required:
  - `./scripts/verify.sh`
  - Проверка, что `orchestrator.toml` и `run.sh` одинаково описывают bounded Phase 5 policy.
- Expected verify result (`exit code 0`).

## Open Questions
- Нужно ли позже добавить явный machine-readable marker для Phase 5 rerun budget, чтобы Monitor мог проверять policy не только по prompt text.
