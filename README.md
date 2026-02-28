# Multi-Agent FastAPI Backend Workflow Template

Этот README описывает процесс работы multi-agent команды над FastAPI backend-проектом.  
Шаблон зафиксирован под FastAPI stack и не рассчитан на другие web-framework'и без отдельной адаптации.

Подробный разбор того, как работает шаблон "от и до": `docs/TEMPLATE_DETAILED_GUIDE.md`
Machine-readable stack profile проекта: `project-stack.toml`

## Цель

Собрать backend, в котором:

- архитектурные решения зафиксированы и согласованы;
- API и БД совместимы и стабильны;
- тесты и verify-проходы зелёные;
- нет blocker-рисков по безопасности и корректности.

## Как создать новый backend из шаблона

1. Скопировать шаблон в новый репозиторий.
2. Проверить и при необходимости обновить `project-stack.toml` под реальный стек проекта.
3. Заполнить `TZ_TEMPLATE.md` или создать отдельный `backend_tz_from_template.md` на его основе.
4. Добавить или уточнить reproducible entrypoint'ы проекта, если они уже известны:
   - `./scripts/dev-up.sh`
   - `./scripts/dev-api.sh`
   - `make dev-up`
   - `make run-api`
   - `make verify`
5. Проверить сам шаблон:

```bash
./run.sh verify
```

6. Запустить первый multi-agent прогон:

```bash
./run.sh codex
```

или:

```bash
./run.sh codex backend_tz_from_template.md
```

## Что должен заполнить пользователь

До первого прогона пользователь должен явно заполнить хотя бы эти входы:

- `project-stack.toml`: реальный stack profile, entrypoint'ы API и verify, container runtime, broker/cache/DB.
- `TZ_TEMPLATE.md` или отдельный `backend_tz_from_template.md`: цель MVP, FR/NFR, API/DB assumptions, RBAC, acceptance checklist.

Желательно подготовить заранее:

- `README.md` разделы с project-specific командами запуска и проверки, если они отличаются от шаблонных.
- `./scripts/dev-up.sh` и `./scripts/dev-api.sh` либо `make`/`task` entrypoint'ы, если локальный startup flow уже известен.

Не нужно вручную заполнять фазовые артефакты `docs/*.md` и `openapi.yaml` как готовый результат до прогона.
Они уже существуют как template artifacts и должны быть обновлены агентами по ходу workflow.

## Stack Assumptions

Source of truth для стека и runtime tooling: `project-stack.toml`

Профиль по умолчанию:

- Language/framework: `python` + `fastapi`
- Schemas/validation: `Pydantic`
- Persistence/migrations: `SQLAlchemy` + `Alembic`
- DI: `dishka`
- Messaging: `faststream` + `redis` / `redis-streams`
- Cache/DB: `redis` + `postgres`
- Dev containers: `podman` + `podman-compose`
- API runtime: `uvicorn` -> `app.main:app`
- Verify entrypoint: `./scripts/verify.sh`

`project-stack.toml` не является lockfile версий. Это machine-readable профиль технологического выбора и entrypoint'ов, который агенты должны читать до любых предположений о стеке.

## Роли агентов

## Orchestrator

- Управляет фазами и порядком выполнения.
- Не пишет прод-код и не меняет схему БД напрямую.
- Разрешает конфликты между контрактами.

## Architect

- Фиксирует архитектурные решения (очереди, кэш, границы безопасности, модель консистентности).
- Пишет архитектурный контракт в `docs/architecture.md` и ADR в `docs/adr/ADR-*.md`.
- Эскалирует изменения контрактов через Change Request.

## DB

- Владеет схемой данных, миграциями и индексами.
- Ведёт журнал schema-level решений в `docs/schema-decisions.md`.
- Отвечает за ограничения, целостность и миграционную безопасность.
- Не меняет API-контракты без Change Request.

## API

- Владеет публичным FastAPI-контрактом в `openapi.yaml` (OpenAPI, схемы запрос/ответ, ошибки, идемпотентность).
- Проверяет совместимость с БД и архитектурой.
- Не меняет БД напрямую.

## Devenv

- Владеет локальной dev-средой и reproducible startup flow.
- Читает `project-stack.toml` как source of truth для container runtime, compose tool и API entrypoint'а.
- При необходимости поднимает зависимости и само API.
- Для контейнерной dev-среды использует `podman` и `podman-compose`.
- Ведёт `docs/dev-environment.md` как канонический runtime/bootstrap артефакт.

## Worker

- Реализует FastAPI runtime: бизнес-логику, сервисы, репозитории и интеграции.
- Читает `project-stack.toml` для runtime/DI/messaging assumptions перед реализацией.
- Следует контрактам Architect/DB/API.
- Не меняет архитектурные и контрактные решения без согласования.

## Tests

- Пишет unit/integration/contract/security тесты.
- Читает `project-stack.toml` для test runner, DB/cache/message infra и verify entrypoint'а.
- Для integration/contract сценариев исходит из FastAPI/ASGI runtime.
- Ведёт `docs/test-matrix.md` как канонический список test coverage.
- Поддерживает матрицу доступов и негативные сценарии.
- Не переписывает прод-код без необходимости.

## Security Reviewer (read-only)

- Проверяет broken access control, ownership, auth/rbac gaps и secret leakage.
- Не вносит изменения в код и не пишет финальный gate.

## Consistency Reviewer (read-only)

- Проверяет idempotency, transaction boundaries, race conditions и duplicate side effects.
- Не вносит изменения в код и не пишет финальный gate.

## Performance Reviewer (read-only)

- Проверяет N+1, индексы, тяжелые сортировки, query shape и bottleneck'и FastAPI + DB слоя.
- Не вносит изменения в код и не пишет финальный gate.

## Gatekeeper

- Ждёт результаты review-агентов и агрегирует findings.
- Ставит финальный gate и ведёт `docs/final-review.md`.
- Не делает глубокий аудит вместо специализированных review-агентов.

## Explorer (read-only)

- Анализирует структуру проекта, ТЗ и контракты.
- Находит противоречия и пробелы в требованиях.

## Monitor (read-only)

- Запускает единый verify entrypoint и собирает сводку.
- Читает `project-stack.toml` как source of truth для verify entrypoint и container runtime.
- Не меняет код.

## Порядок verify entrypoint

Machine-readable source of truth для verify: `project-stack.toml` (`verify_entrypoint`).

Если entrypoint из stack profile отсутствует или временно невалиден, Monitor/Tests используют fallback порядок:

1. `./scripts/verify.sh`
2. `make verify`
3. `task verify`
4. fallback: команды из раздела "How to test" в README

Если для dev-среды нужны контейнеры, стандарт проекта: `podman` + `podman-compose`.

## Workflow по фазам

Phase 1 — Architecture

- Architect фиксирует архитектурные решения и ограничения.
- Артефакты фазы: `docs/architecture.md` и минимум один `docs/adr/ADR-*.md`.

Phase 2 — Contracts

- DB и API работают параллельно.
- Orchestrator проверяет совместимость контрактов.
- Артефакты фазы: `openapi.yaml` и `docs/schema-decisions.md`.

Phase 3 — Dev Environment + Implementation

- Devenv подготавливает локальную dev-среду и при необходимости поднимает сервисы/API.
- Worker реализует функциональность строго по контрактам в runtime backend-коде.
- Артефакт фазы: `docs/dev-environment.md`.
- Изменения только в документации не считаются завершением Phase 3.

Phase 4 — Testing

- Tests добавляет/обновляет тесты.
- Monitor запускает verify entrypoint и публикует результат.
- Артефакт фазы: `docs/test-matrix.md`.

Phase 5 — Review

- Security Reviewer, Consistency Reviewer и Performance Reviewer работают параллельно.
- Gatekeeper агрегирует findings и ставит финальный gate.
- При blocker-issue задача возвращается соответствующему владельцу фазы.
- Артефакт фазы: `docs/final-review.md`.

## Что должно появиться после первого multi-agent прогона

Минимально разумный первый прогон должен оставить после себя не только summary, но и файловые следы работы:

- `docs/architecture.md` с `Status != template`
- минимум один `docs/adr/ADR-*.md`
- `openapi.yaml` с `x-template-status != template`
- `docs/schema-decisions.md` с `Status != template`
- `docs/dev-environment.md` с `Status != template`
- `docs/test-matrix.md` с `Status != template`
- `docs/final-review.md` с `Status != template`

Кроме документов, должны появиться реальные backend-изменения хотя бы в одной из зон:

- runtime-код
- миграции
- тесты

Если во время прогона всплыл конфликт между контрактами, допустимым артефактом также считается явный Change Request, а не молчаливое расхождение между API и DB.

## Фазовые артефакты по умолчанию

- `docs/architecture.md`: Phase 1, владелец `Architect`.
- `docs/adr/ADR-*.md`: Phase 1, владелец `Architect`.
- `openapi.yaml`: Phase 2, владелец `API`.
- `docs/dev-environment.md`: Phase 3, владелец `Devenv`.
- `docs/schema-decisions.md`: Phase 2, владелец `DB`.
- `docs/test-matrix.md`: Phase 4, владелец `Tests`.
- `docs/final-review.md`: Phase 5, владелец `Gatekeeper`.

Правило завершения фазы:

- Markdown-артефакт должен существовать и быть обновлён из template-state (`Status:` не равен `template`).
- `openapi.yaml` должен существовать и быть обновлён из template-state (`x-template-status:` не равен `template`).
- Orchestrator проверяет фазу по файлам и их статус-маркерам, а не по summary агента.

## Правила взаимодействия

1. Контракты API/DB/Architecture не меняются без Change Request.
2. DB не изменяет API-контракт напрямую.
3. API не изменяет схему БД напрямую.
4. Devenv владеет startup-командами, env bootstrap и локальными сервисами/API.
5. Worker не переопределяет архитектурные решения.
6. Security Reviewer, Consistency Reviewer, Performance Reviewer, Explorer и Monitor работают в read-only режиме.
7. Gatekeeper агрегирует review-findings и публикует единственное финальное gate-решение.
8. Все конфликтующие решения фиксируются явно и маршрутизируются через Orchestrator.

## Change Request Protocol

Если изменение затрагивает контракт:

1. Зафиксировать:
   - что меняется;
   - почему текущее состояние блокирует работу;
   - impact на API/DB/tests/release.
2. Передать CR в Orchestrator.
3. Orchestrator определяет порядок обновления фаз и ответственных.

## Acceptance Conditions (Definition of Done)

Проект считается готовым, когда:

- реализованы все целевые endpoint'ы текущей версии API;
- покрыты тестами RBAC/ownership и критичные негативные сценарии;
- миграции применяются на чистой БД;
- идемпотентность критичных mutation endpoint'ов подтверждена тестами;
- подключены логи/метрики и есть минимальные health-проверки;
- локальная dev-среда и API стартуют воспроизводимо;
- `project-stack.toml` соответствует реальному стеку и entrypoint'ам проекта;
- обновлены фазовые артефакты по умолчанию: `docs/architecture.md`, `docs/adr/ADR-*.md`, `openapi.yaml`, `docs/dev-environment.md`, `docs/schema-decisions.md`, `docs/test-matrix.md`, `docs/final-review.md`;
- backend-изменения внесены в исходники и/или миграции и/или тесты (не только в docs/.codex);
- `./scripts/verify.sh` завершается с exit code `0`;
- у Gatekeeper нет blocker issues по итогам review.

## Что считается плохим прогоном

Плохой прогон для этого шаблона обычно выглядит так:

- изменились только `docs/`, `.codex/` или ТЗ, но нет runtime-кода, миграций или тестов;
- фазовые артефакты остались в template-state (`Status: template` или `x-template-status: template`);
- `project-stack.toml` не соответствует реальному проекту, а агенты работают по ложным assumptions;
- Orchestrator остановился на summary, хотя `verify` не зелёный или у Gatekeeper есть blocker findings;
- API и DB разошлись, но Change Request не был оформлен явно;
- для тестов или verify нужен поднятый стек, но Devenv не был задействован;
- первый прогон не оставил воспроизводимых startup/verify подсказок для следующей итерации.

## Запуск через run.sh

В корне проекта есть обёртка `run.sh` для типовых запусков.

Проверки:

```bash
./run.sh
./run.sh verify
```

Multi-agent запуск Codex:

```bash
./run.sh codex
./run.sh codex backend_tz_from_template.md
```

Справка по командам:

```bash
./run.sh help
```

Требования для `./run.sh codex`:

- команда `codex` доступна в `PATH`;
- в Codex включен feature flag `multi_agent`.

## How to test

Базовый entrypoint проверки:

```bash
./run.sh verify
```

Прямой запуск verify-скрипта:

```bash
./scripts/verify.sh
```

Альтернативные entrypoint'ы (если поддерживаются проектом):

```bash
make verify
task verify
```
