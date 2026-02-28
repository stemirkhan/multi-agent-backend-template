# ADR-20260228-add-stack-profile

## ADR ID
`ADR-20260228-add-stack-profile`

## Status
`accepted`

## Context
- Шаблон уже зафиксирован под FastAPI-стек, но до этого технологические ожидания были разбросаны по README, ТЗ, prompt'ам и agent instructions.
- Из-за этого агентам приходилось повторно выводить framework/runtime/tooling из текста, а не читать единый machine-readable контракт.
- Для Devenv, Worker, Tests и Monitor особенно важны точные поля по runtime, DI, messaging, контейнерам и verify entrypoint'у.

## Decision
- Добавить в корень репозитория `project-stack.toml` как machine-readable stack profile проекта.
- Сделать `project-stack.toml` source of truth для `language`, `framework`, `orm`, `migration_tool`, `test_runner`, `di_library`, `message_framework`, `message_broker`, `message_transport`, `cache`, `db`, `container_runtime`, `compose_tool`, `api_runner`, `api_entrypoint`, `verify_entrypoint`.
- Обязать Orchestrator и runtime-oriented агентов сначала читать `project-stack.toml`, а уже потом использовать README/TZ как поясняющий контекст.

## Alternatives Considered
1. `STACK.md`: проще читать человеку, но хуже для verify и автоматизированного использования агентами.
2. `project-stack.toml`: выбранный вариант; его удобно парсить, валидировать и использовать как source of truth.
3. `hardcoded prompts only`: меньше файлов, но стек остается размазанным и хуже поддерживается.

## Consequences
- Positive outcomes:
  - Агенты получают единый machine-readable контракт по стеку и entrypoint'ам.
  - `verify.sh` может валидировать наличие и базовую корректность stack profile.
  - README и ТЗ остаются человекочитаемыми, но перестают быть единственным источником стека.
- Negative outcomes and debt:
  - `project-stack.toml` придется поддерживать в актуальном состоянии вручную.
  - При расширении шаблона под другие стеки придется обновлять schema и agent instructions.

## Contract Impact
- API impact:
  - API Agent перестает гадать framework/runtime assumptions и читает их из `project-stack.toml`.
- DB impact:
  - DB Agent получает явный профиль ORM/migration/db/cache assumptions.
- Worker/tests/monitor impact:
  - Devenv, Worker, Tests и Monitor опираются на stack profile для runtime, DI, messaging, контейнеров и verify entrypoint'а.

## Rollout Plan
1. `template`: добавить `project-stack.toml` с дефолтным FastAPI profile.
2. `orchestrator/docs/verify`: синхронизировать prompt'ы, agent instructions и template checks.

## Rollback Plan
- Trigger condition:
  - Stack profile не используется агентами на практике или создает больше drift, чем пользы.
- Safe rollback steps:
  - Удалить `project-stack.toml`.
  - Вернуть textual stack assumptions как единственный источник.
  - Убрать stack profile из verify и agent instructions.

## Verification
- Checks/tests required:
  - `./scripts/verify.sh`
  - Проверка, что `project-stack.toml` существует, парсится и содержит обязательные поля.
  - Проверка, что docs/prompt'ы ссылаются на stack profile как на source of truth.
- Expected verify result (`exit code 0`).

## Open Questions
- Нужна ли в будущем schema-версия с nested sections вместо flat keys.
