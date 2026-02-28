# Multi-Agent FastAPI Backend Template: подробный разбор

Этот документ объясняет, как устроен шаблон multi-agent backend workflow в этом репозитории, какие файлы за что отвечают, как именно запускается оркестрация, как работают агенты, где лежат ограничения системы и что реально происходит во время запуска.

Документ написан для случая, когда нужно понять шаблон "от и до", а не просто знать одну команду запуска.

## 1. Что это за шаблон

Это не backend-фреймворк и не готовое приложение.

Это orchestration template для Codex для FastAPI backend-проектов, который помогает:

- формализовать архитектуру;
- развести ответственность между ролями;
- заставить workflow идти по фазам;
- использовать sub-agents для параллельной и специализированной работы;
- не завершать backend-зачу только на документах;
- проходить через проверку (`verify`) и финальный review.

Идея шаблона такая:

1. Есть один главный агент: `Orchestrator`.
2. Он читает ТЗ и правила проекта.
3. Дальше он запускает специализированных агентов по фазам.
4. Каждый агент отвечает только за свою область.
5. Если найден конфликт между контрактами, запускается Change Request flow.
6. Если всё успешно, workflow доходит до implementation, tests, verify и review.

То есть шаблон решает не задачу "как написать backend", а задачу "как управлять написанием FastAPI backend через набор специализированных ролей".

## 2. Основные файлы репозитория

Ключевые файлы:

- `.codex/config.toml`
- `.codex/agents/*.toml`
- `.codex/skills/*`
- `project-stack.toml`
- `.env.example`
- `.gitignore`
- `README.md`
- `TZ_TEMPLATE.md`
- `docs/architecture.md`
- `docs/adr/`
- `openapi.yaml`
- `docs/dev-environment.md`
- `docs/schema-decisions.md`
- `docs/test-matrix.md`
- `docs/final-review.md`
- `run.sh`
- `scripts/verify.sh`

### `.codex/config.toml`

Это project-level конфиг Codex для этого репозитория.

Он задает:

- включён ли multi-agent режим;
- лимиты на агентов;
- список зарегистрированных агентных ролей;
- какие файлы описывают поведение каждой роли.

В текущем шаблоне:

```toml
[features]
multi_agent = true

[agents]
max_threads = 12
max_depth = 6
```

Где:

- `multi_agent = true` включает инструменты multi-agent collaboration;
- `max_threads = 12` задает максимум параллельных агентных потоков;
- `max_depth = 6` задает максимальную глубину вложенности sub-agent chain.

Ниже в этом же файле есть секции вида:

```toml
[agents.orchestrator]
description = "..."
config_file = "agents/orchestrator.toml"
```

Это registry ролей. Он говорит Codex:

- что такая роль существует;
- как ее показать в системе;
- какой `.toml` использовать для ее инструкций.

### `.codex/agents/*.toml`

Это конфиги конкретных ролей.

Каждый агентный файл задает:

- модель;
- уровень reasoning effort;
- иногда sandbox mode;
- главное: `developer_instructions`.

Именно `developer_instructions` определяет, что роль должна делать, чего ей нельзя делать и как выглядит успешный результат.

### `.codex/skills/*`

Здесь лежат локальные skills, которые используются агентами как стандартизированные workflow.

В текущем шаблоне уже есть:

- `architecture-decision-record`
- `change-request-writer`
- `db-design-checklist`
- `backend-bootstrap`

Skills нужны, чтобы важные операции выполнялись по повторяемому процессу, а не "каждый раз по-своему".

### `README.md`

Это человекочитаемая документация по шаблону:

- роли;
- workflow по фазам;
- правила взаимодействия;
- conditions of done;
- способы запуска.

README объясняет логику системы, но не управляет Codex напрямую.

### `TZ_TEMPLATE.md`

Это шаблон ТЗ, который должен заполняться под конкретный backend-проект.

Именно в нем фиксируются:

- цель MVP;
- функциональные требования;
- NFR;
- архитектурные ожидания;
- контракт БД;
- API v1;
- RBAC;
- события;
- тестовая стратегия;
- acceptance checklist.

По сути, это основной входной документ для multi-agent прогона.

### `project-stack.toml`

Это machine-readable stack profile проекта.

Он фиксирует:

- `language`
- `framework`
- `orm`
- `migration_tool`
- `test_runner`
- `di_library`
- `message_framework`
- `message_broker`
- `message_transport`
- `cache`
- `db`
- `container_runtime`
- `compose_tool`
- `api_runner`
- `api_entrypoint`
- `verify_entrypoint`

Практический смысл:

- агенты сначала читают `project-stack.toml`, а потом уже README и ТЗ;
- `verify.sh` может валидировать профиль автоматически;
- `Devenv`, `Worker`, `Tests` и `Monitor` перестают гадать runtime/tooling stack.

Это не lockfile и не pip/poetry manifest.

Это декларативный контракт технологического выбора и entrypoint'ов проекта.

### Stack assumptions

Этот шаблон теперь жёстко зафиксирован под стек, а его machine-readable source of truth — `project-stack.toml`:

- `FastAPI`
- `Pydantic`
- `SQLAlchemy`
- `Alembic`
- `dishka`
- `faststream`
- `redis` / `redis-streams`
- `postgres`
- `podman` + `podman-compose` для dev-среды

### Hard defaults

В шаблон теперь жёстко зашиты несколько архитектурно-прикладных правил:

- единый app-level слой ошибок с `code`, `message`, `details`;
- `.env` не коммитится, в репозитории хранится `.env.example`;
- настройки читаются через `pydantic-settings`;
- бизнес-логика и транзакции живут в сервисах/UoW;
- репозитории не делают `commit` / `rollback` и не содержат бизнес-логики;
- публичные интерфейсы должны быть типизированы.

### Фазовые артефакты по умолчанию

В шаблон теперь заранее добавлены канонические output files по фазам:

- `docs/architecture.md`
- `docs/adr/`
- `openapi.yaml`
- `docs/dev-environment.md`
- `docs/schema-decisions.md`
- `docs/test-matrix.md`
- `docs/final-review.md`

Это нужно для того, чтобы Orchestrator проверял прохождение фаз по реальным файлам, а не по свободному summary агента.

Для containerized dev-среды стандарт этого шаблона теперь фиксирован:

- `podman`
- `podman-compose`

Для markdown-артефактов используется маркер:

```text
Status: template
```

Для OpenAPI используется маркер:

```yaml
x-template-status: template
```

Пока маркер не обновлен, фаза считается незавершенной.

### `run.sh`

Это локальная обертка для типовых команд:

- запуск `verify`;
- запуск `codex` с уже готовым orchestration prompt.

Она нужна, чтобы не помнить длинные команды вручную.

### `scripts/verify.sh`

Это verify entrypoint шаблона.

Сейчас он валидирует сам шаблон, а не конкретный продуктовый backend.

То есть он проверяет:

- корректность agent TOML;
- наличие обязательных ролей;
- наличие `.env.example` и `.gitignore` для локальной безопасности;
- наличие и базовую валидность `project-stack.toml`;
- наличие verify entrypoint в README;
- наличие default phase artifacts и их базовых status-маркеров;
- наличие и валидность skills.

Важно: на текущем этапе `verify.sh` проверяет инфраструктуру шаблона, а не качество реального backend-кода.

## 3. Как Codex вообще подхватывает этот шаблон

Когда ты запускаешь Codex в каталоге проекта, он смотрит на несколько слоев конфигурации.

Практически важные уровни:

1. CLI flags
2. project config: `.codex/config.toml`
3. user config: `~/.codex/config.toml`
4. встроенные defaults

Это значит:

- если ты запустил `codex --enable multi_agent`, это имеет приоритет над дефолтами;
- если проект trusted, Codex читает `.codex/config.toml` проекта;
- если проект не trusted, он может игнорировать project config.

В реальной работе шаблон опирается на то, что:

- проект доверенный;
- feature `multi_agent` активен;
- `codex` запускается внутри этого репозитория.

## 4. Что означает `multi_agent`

`multi_agent` сам по себе не означает, что "код magic-образом напишется несколькими моделями".

Это означает, что главному агенту становится доступен набор инструментов для multi-agent orchestration:

- `spawn_agent`
- `send_input`
- `wait`
- `close_agent`
- и связанные коллаборативные механики

Тогда главный агент может:

- запускать дочерних агентов;
- распределять им роли;
- ждать их результаты;
- запускать их параллельно;
- закрывать завершенные агенты;
- эскалировать задачи дальше по фазам.

То есть `multi_agent` превращает один агентный прогон в координаторский pipeline.

## 5. Что означают `max_threads` и `max_depth`

Это два очень важных лимита.

### `max_threads`

Пример:

```toml
max_threads = 12
```

Это максимум одновременно активных agent threads.

Практически:

- если Orchestrator захочет сразу запустить 20 sub-agents, система ограничит параллелизм;
- при достижении лимита новые запускаемые агенты могут не стартовать сразу;
- слишком маленькое значение делает workflow медленным и более последовательным;
- слишком большое значение может раздувать контекст и давать хаос.

Для вашего шаблона `12` это уже "достаточно свободный" лимит.

### `max_depth`

Пример:

```toml
max_depth = 6
```

Это глубина вложенности agent spawning.

Например:

1. главный агент запускает `Orchestrator`
2. `Orchestrator` запускает `DB`
3. `DB` запускает еще одного узкого агента
4. тот запускает еще кого-то

Каждый новый уровень увеличивает depth.

Если depth превышен, Codex больше не даст порождать новых агентов на следующем уровне.

Практически:

- маленький `max_depth` обрезает сложные orchestration chains;
- большой `max_depth` дает гибкость, но может усложнить контроль.

Для большинства backend-задач `4-6` обычно хватает.

## 6. Как устроены роли

Ниже кратко описано, как работает каждая роль именно в этом шаблоне.

### Orchestrator

Файл: `.codex/agents/orchestrator.toml`

Это главный управляющий агент.

Он:

- не пишет прод-код;
- не меняет схему БД напрямую;
- управляет порядком фаз;
- запускает другие роли;
- ловит конфликты между контрактами;
- решает, когда нужен CR;
- определяет, кому идти следующим;
- сначала читает `project-stack.toml`, чтобы не гадать framework/runtime/tooling assumptions.

Самое важное правило текущего шаблона:

- backend-задача не считается завершенной, если изменения только в `docs`, `.codex` или ТЗ;
- должны быть изменения в runtime-коде и/или миграциях и/или тестах.
- каждая фаза должна оставить обязательные артефакты по фиксированным путям.

То есть Orchestrator должен довести процесс до реальных backend-артефактов.

### Architect

Файл: `.codex/agents/architect.toml`

Отвечает за системные решения:

- кэш;
- очередь;
- security boundaries;
- transactional boundaries;
- soft delete policy;
- money representation.

Его задача не писать код, а зафиксировать архитектуру как контракт.

Для этого он использует skill `architecture-decision-record`.

Ожидаемые артефакты:

- `docs/architecture.md`
- минимум один `docs/adr/ADR-*.md`

### API

Файл: `.codex/agents/api.toml`

Отвечает за публичный контракт:

- endpoint list;
- request/response schemas;
- error model;
- pagination/filter/sort;
- idempotency policy;
- совместимость с БД.

Важно:

- API агент не владеет миграциями;
- если для API нужно поменять БД, он обязан оформить CR.
- канонический контрактный файл по умолчанию: `openapi.yaml`;
- framework/runtime/messaging assumptions нужно брать из `project-stack.toml`, а не выводить из общих рассуждений.

### DB

Файл: `.codex/agents/db.toml`

Отвечает за:

- схему;
- миграции;
- индексы;
- ограничения;
- сиды;
- миграционную безопасность.

Он обязан работать через `db-design-checklist`, когда проектирует БД.

Если API и DB расходятся, DB сам не меняет API-контракт, а оформляет CR или ждет оркестрацию через Orchestrator.

Также DB читает `project-stack.toml` как источник истины по ORM/migration/db/cache assumptions.

Ожидаемый артефакт:

- `docs/schema-decisions.md`

### Devenv

Файл: `.codex/agents/devenv.toml`

Это агент локальной dev-среды.

Он отвечает за:

- reproducible startup flow;
- локальные зависимости;
- env/bootstrap entrypoint'ы;
- запуск FastAPI API для разработки и проверки;
- минимальные dev-tooling изменения, если без них pipeline не может идти дальше.
- container lifecycle через `podman` / `podman-compose`;
- чтение `project-stack.toml` как канонического stack/runtime profile.

Важно:

- Devenv не владеет бизнес-логикой;
- Devenv не должен менять API/DB контракт без CR;
- если для старта нужны секреты или внешний доступ, он должен явно вернуть блокер.
- если среда контейнеризирована, канонический способ подъема: `podman-compose`.
- если нужен локальный HTTP runtime, канонический класс команды — FastAPI/ASGI startup.
- `.env` не должен попадать в git; канонический tracked файл для локальных настроек — `.env.example`.
- настройки dev/runtime слоя должны читаться через `pydantic-settings`.

Ожидаемый артефакт:

- `docs/dev-environment.md`

### Worker

Файл: `.codex/agents/worker.toml`

Это агент, который должен писать backend implementation.

Именно он отвечает за:

- бизнес-логику;
- сервисы;
- репозитории;
- runtime-код;
- интеграции;
- кэш и фоновые задачи;
- корректные транзакционные границы.

В текущем шаблоне уже закреплено правило:

- Worker не должен ограничиваться только документами;
- для backend-задачи должны появляться изменения в коде, миграциях или тестах.
- если для локальной разработки/проверки нужен поднятый стек, Worker должен идти через Devenv, а не собирать среду ad-hoc;
- runtime/DI/messaging assumptions Worker должен брать из `project-stack.toml`;
- если foundation layer отсутствует, Worker должен сначала использовать `backend-bootstrap`.
- сервисы владеют бизнес-логикой и транзакциями/UoW, а репозитории остаются data-access слоем без `commit` / `rollback`.
- внутренние слои должны использовать app-level exceptions вместо `HTTPException` и сырых library errors.

### Tests

Файл: `.codex/agents/tests.toml`

Отвечает за:

- unit tests;
- integration tests;
- contract tests;
- access matrix;
- негативные сценарии;
- проверку идемпотентности.

Он не должен переписывать прод-код без необходимости.

Также Tests должен читать `project-stack.toml`, чтобы не гадать test runner, DB/cache infra и verify entrypoint.

Ожидаемый артефакт:

- `docs/test-matrix.md`

### Monitor

Файл: `.codex/agents/monitor.toml`

Это read-only агент, который не меняет код.

Его роль:

- выбрать verify entrypoint;
- запустить его;
- коротко суммаризировать результат.
- если verify не стартует из-за неподнятой среды/API, вернуть точный блокер в Devenv через Orchestrator;
- брать verify/container assumptions из `project-stack.toml`.

Он не должен вручную дублировать все проверки, если проект уже определил единый `verify`.

### Security Reviewer

Файл: `.codex/agents/security-reviewer.toml`

Это read-only reviewer по security/access области.

Он смотрит на:

- broken access control;
- ownership;
- auth/rbac gaps;
- утечки секретов;
- security boundary mistakes.

Он не пишет финальный gate, а только возвращает findings.

### Consistency Reviewer

Файл: `.codex/agents/consistency-reviewer.toml`

Это read-only reviewer по consistency/reliability области.

Он смотрит на:

- idempotency;
- transaction boundaries;
- гонки;
- duplicate side effects;
- retry/double-submit risks.

Он не пишет финальный gate, а только возвращает findings.

### Performance Reviewer

Файл: `.codex/agents/performance-reviewer.toml`

Это read-only reviewer по performance/data-access области.

Он смотрит на:

- N+1;
- индексы;
- тяжёлые сортировки;
- query shape;
- bottleneck'и FastAPI + DB слоя.

Он не пишет финальный gate, а только возвращает findings.

### Gatekeeper

Файл: `.codex/agents/gatekeeper.toml`

Это агрегатор review-результатов.

Он:

- ждет findings от review-агентов;
- убирает дубли;
- фиксирует blocker/pass решение;
- пишет финальный артефакт review.

Если Gatekeeper ставит blocker, workflow не должен считаться завершенным.

Ожидаемый артефакт:

- `docs/final-review.md`

### Explorer

Файл: `.codex/agents/explorer.toml`

Это быстрый read-only разведчик.

Он полезен, когда:

- нужно быстро понять структуру репо;
- нужно найти противоречия;
- нужно собрать карту модулей и зависимостей.

## 7. Что такое skills и как они включаются

Skills в этом шаблоне нужны для узких, повторяемых сценариев.

Сейчас используются четыре базовых skills.

### `architecture-decision-record`

Используется, когда нужно формально оформить архитектурное решение.

Результат обычно выглядит как ADR:

- решение;
- альтернативы;
- trade-offs;
- impact;
- rollout / rollback.

### `change-request-writer`

Используется, когда один агент не может продолжить без изменения чужого контракта.

Типичный случай:

- API говорит: "мне не хватает поля в БД";
- DB говорит: "я не могу это добавить без согласования";
- Orchestrator требует CR.

Тогда создается формализованный Change Request.

### `db-design-checklist`

Используется DB агентом для системной проверки:

- таблиц;
- ключей;
- индексов;
- soft delete;
- миграционной безопасности;
- совместимости с API.

### `backend-bootstrap`

Используется, когда в репозитории ещё нет нормального backend foundation layer.

Типичные случаи:

- нет runtime skeleton под `FastAPI`;
- нет ASGI entrypoint;
- нет слоя кастомных исключений;
- нет базового DI/messaging/bootstrap layout;
- нет минимального test/dev foundation.

Skill нужен не для бизнес-логики, а для создания стартовой структуры проекта, чтобы `Worker` и `Devenv` не строили фундамент ad-hoc.

Skills не запускаются "магией сами по себе". Обычно Orchestrator или конкретный агент:

- либо прямо упоминает skill;
- либо по инструкции должен использовать skill при определенном типе задачи.

## 8. Как работает `run.sh`

Файл: `run.sh`

Сейчас он поддерживает две основные команды:

```bash
./run.sh verify
./run.sh codex [tz_file]
```

### `./run.sh verify`

Это просто удобный wrapper для:

```bash
./scripts/verify.sh
```

### `./run.sh codex [tz_file]`

Это wrapper для запуска Codex с уже встроенным orchestration prompt.

Что делает скрипт шаг за шагом:

1. Определяет корень проекта.
2. Переходит в него.
3. Проверяет, что `codex` доступен в `PATH`.
4. Проверяет, что файл ТЗ существует.
5. Собирает prompt для Orchestrator.
6. Запускает:

```bash
codex --enable multi_agent "$prompt"
```

Если `tz_file` не передан, используется:

```bash
TZ_TEMPLATE.md
```

### Какой prompt сейчас формируется

Логика prompt'а такая:

- идти по `Phase 1..5` итерациями;
- не останавливаться, пока:
  - фазовые артефакты по умолчанию не обновлены из template-state;
  - `verify` не дал `exit 0`;
  - Gatekeeper не перестал выдавать blocker-findings;
  - acceptance checklist в ТЗ не закрыт;
  - не появились backend-изменения в коде/миграциях/тестах;
- если найден blocker, агент должен:
  - сам инициировать CR;
  - назначить нужного агента;
  - перезапустить только нужные фазы;
- если для реализации/тестов/verify нужна локальная среда или поднятый API, сначала должен идти Devenv;
- остановка допускается только если нужен внешний человеческий input:
  - секрет;
  - доступ;
  - бизнес-решение.

Это важный момент: prompt сейчас делает Orchestrator гораздо более "настойчивым", чем просто "пройди workflow и напиши summary".

## 9. Как работает workflow по фазам

Текущий pipeline задуман так.

### Phase 1 — Architecture

Оркестратор запускает Architect.

Ожидается:

- зафиксирована архитектура;
- записаны системные решения;
- оформлены ADR;
- выявлены архитектурные неопределенности.
- обновлены `docs/architecture.md` и минимум один `docs/adr/ADR-*.md`.

Это не implementation phase. Здесь создается architectural contract.

### Phase 2 — Contracts

Оркестратор запускает API и DB.

Желательно параллельно.

Они проверяют:

- согласованность contract surface;
- соответствие типов;
- nullable / required logic;
- enum compatibility;
- индексы под реальные запросы;
- idempotency и связанные storage assumptions.

Артефакты фазы:

- `openapi.yaml`
- `docs/schema-decisions.md`

Если находится конфликт:

- нельзя "тихо исправить соседний контракт";
- нужен явный CR flow.

### Phase 3 — Dev Environment + Implementation

Оркестратор сначала запускает Devenv, затем Worker.

Devenv должен:

- определить стандартный способ локального старта;
- поднять нужные сервисы, если они требуются;
- при необходимости поднять само API;
- зафиксировать команды и ограничения в `docs/dev-environment.md`.

После этого Worker делает реальную backend-реализацию:

- код;
- миграции;
- тесты;
- интеграции;
- фоновые workers;
- runtime-изменения.

В текущем шаблоне docs-only завершение этой фазы считается некорректным.

Артефакты фазы:

- `docs/dev-environment.md`
- runtime-код и/или миграции и/или тесты

### Phase 4 — Testing

Оркестратор запускает Tests и Monitor.

Tests:

- добавляет тесты;
- актуализирует покрытие;
- проверяет test strategy.
- обновляет `docs/test-matrix.md`.
- использует dev-среду проекта на `podman` / `podman-compose`, если тесты зависят от контейнеров.
- если среда не готова, возвращает блокер в Devenv через Orchestrator.

Monitor:

- запускает verify entrypoint;
- сообщает exit code;
- суммаризирует упавшие части.
- если verify зависит от containerized dev-среды, опирается на `podman` / `podman-compose`.
- если verify не стартует из-за среды, возвращает задачу в Devenv.

### Phase 5 — Review

Оркестратор сначала запускает `Security Reviewer`, `Consistency Reviewer` и `Performance Reviewer` параллельно.

После этого запускается `Gatekeeper`.

Review-агенты не должны писать код. Они должны:

- найти blocker/major/minor issues;
- указать, где проблема;
- объяснить, как воспроизвести;
- предложить, как исправить.

Gatekeeper не должен делать глубокий аудит вместо них. Он должен:

- агрегировать findings;
- определить итоговый blocker/pass gate;
- указать, кому возвращать задачу при blocker.

Артефакт фазы:

- `docs/final-review.md`

Если Gatekeeper ставит blocker, Orchestrator обязан продолжить цикл, а не просто завершить задачу summary.

## 10. Почему workflow может "остановиться"

Это один из самых важных практических моментов.

Остановка бывает двух видов.

### Нормальная остановка

Это когда задача, которую агент понял как конечную, завершена.

Например:

- он прошел все фазы;
- выдал сводку;
- дальше ждет следующую команду.

В interactive `codex` это выглядит как будто "он остановился", но на самом деле сессия просто ждет следующий input.

### Нежелательная остановка

Это когда pipeline оборвался слишком рано.

Основные причины:

1. Слабый prompt  
   Оркестратор решил, что достаточно сделать docs и summary.

2. Нет жестких stop conditions  
   Например, нет требования "не завершать без кода и без green review".

3. Упёрся в лимит системы  
   Например:
   - `max_threads`
   - `max_depth`

4. Нужен внешний input  
   Примеры:
   - секреты;
   - ключи;
   - доступ к внешней среде;
   - неразрешенное бизнес-решение.

5. Gatekeeper поставил blocker, но prompt не заставил довести цикл до конца  
   Из-за этого Orchestrator может закончить summary вместо продолжения remediation loop.

Именно поэтому текущий prompt в `run.sh` ужесточен.

## 11. В чем разница между `codex` и `codex exec`

Это тоже критично для понимания.

### `codex`

Это интерактивный режим.

Что происходит:

- открывается сессия;
- ты видишь progress updates;
- агент может закончить текущую мысль и ждать следующую команду.

Подходит, когда ты хочешь:

- наблюдать процесс;
- вручную вмешиваться;
- после summary сказать "продолжай".

### `codex exec`

Это неинтерактивный режим.

Он больше подходит, когда ты хочешь:

- запускать orchestration как batch job;
- получить финальный результат и выход;
- минимизировать ручные продолжения.

Если задача описана жестко и stop conditions хорошие, `exec` удобнее для длинных прогонов "до конца".

## 12. Как работает `verify.sh`

Сейчас `scripts/verify.sh` делает 7 проверок.

### 1. Parse agent TOML files

Он:

- открывает `.codex/agents/*.toml`
- проверяет, что файлы парсятся;
- проверяет обязательные ключи:
  - `model`
  - `model_reasoning_effort`
  - `developer_instructions`

### 2. Required agents are present

Проверяет наличие обязательных ролей:

- api
- architect
- consistency-reviewer
- db
- devenv
- explorer
- gatekeeper
- monitor
- orchestrator
- performance-reviewer
- security-reviewer
- tests
- worker

### 3. Local security defaults are present

Проверяет, что:

- существует `.env.example`;
- в нём есть базовые переменные локальной конфигурации;
- существует `.gitignore`;
- `.gitignore` игнорирует `.env`, но не блокирует `.env.example`.

### 4. Project stack profile is present and valid

Проверяет, что:

- существует `project-stack.toml`;
- файл парсится как TOML;
- в нём есть обязательные поля профиля;
- `schema_version = 1`;
- шаблон остаётся `python` + `fastapi`;
- `verify_entrypoint` указывает на существующий файл.

### 5. README references verify entrypoint

Проверяет, что в `README.md` упоминается:

```bash
./scripts/verify.sh
```

### 6. Default phase artifacts are present

Проверяется наличие базового набора файлов и директории:

- `docs/architecture.md`
- `docs/adr/`
- `docs/adr/README.md`
- `openapi.yaml`
- `docs/dev-environment.md`
- `docs/schema-decisions.md`
- `docs/test-matrix.md`
- `docs/final-review.md`

Дополнительно проверяются стандартные маркеры:

- `Status:` в markdown-артефактах;
- `x-template-status:` в `openapi.yaml`.

### 7. Project skills are present and valid

Проверяет обязательные skills:

- `change-request-writer`
- `architecture-decision-record`
- `db-design-checklist`
- `backend-bootstrap`

Плюс:

- наличие `SKILL.md`;
- наличие `agents/openai.yaml`;
- отсутствие TODO placeholders;
- совпадение имени skill;
- quick validation через внешний validator, если он доступен.

### Что важно понимать про verify сейчас

Этот `verify` отвечает на вопрос:

"Шаблон настроен и структурно не сломан?"

Он пока не отвечает на вопрос:

"Реальный backend-код корректен и готов к релизу?"

То есть green `verify` сейчас не равен green product quality.

## 13. Как использовать шаблон в новом проекте

Нормальный жизненный цикл такой.

### Шаг 1. Скопировать шаблон в новый репозиторий

Если стартуем с GitHub в пустую папку:

```bash
git clone https://github.com/stemirkhan/multi-agent-backend-template.git my-backend
cd my-backend
```

Если шаблон нужно влить в уже существующий backend-репозиторий:

```bash
cd /path/to/existing-backend
git clone https://github.com/stemirkhan/multi-agent-backend-template.git /tmp/mab-template
rsync -av --exclude '.git' /tmp/mab-template/ ./
rm -rf /tmp/mab-template
chmod +x run.sh scripts/verify.sh scripts/dev-bootstrap.sh
```

Важно:

- не переносить `.git` из шаблона в существующий проект;
- не делать nested git repository вместо нормального merge шаблонных файлов;
- после копирования сразу проверить `project-stack.toml` и путь к ТЗ.

После этого в репозитории уже будут:

- multi-agent config;
- набор ролей;
- skills;
- `project-stack.toml`;
- launcher script;
- verify entrypoint;
- шаблон ТЗ.

### Шаг 2. Проверить `project-stack.toml`

Нужно убедиться, что machine-readable profile соответствует проекту.

Минимально проверить:

- framework/runtime;
- ORM и migration tool;
- test runner;
- cache / broker / transport;
- API и verify entrypoint'ы;
- container runtime и compose tool.

Если `project-stack.toml` не совпадает с реальностью, агенты начнут делать неверные предположения уже на старте.

### Шаг 3. Заполнить ТЗ

Нужно адаптировать `TZ_TEMPLATE.md` под конкретный проект.

Самое важное:

- убрать плейсхолдеры;
- описать FR/NFR;
- заполнить API/DB sections;
- задать acceptance checklist.

Если ТЗ пустое или полу-пустое, pipeline либо застрянет в документах, либо начнет строить слишком много предположений.

### Шаг 4. Проверить, что `codex` настроен

Нужно:

- актуальная версия `codex`;
- включенный `multi_agent`;
- trusted project;
- доступный `codex` в `PATH`.

### Шаг 5. Проверить шаблон

```bash
./run.sh verify
```

Это подтверждает, что template infrastructure в порядке.

### Шаг 6. Запустить orchestration

Если ТЗ в `TZ_TEMPLATE.md`:

```bash
./run.sh codex
```

Если ТЗ в отдельном файле:

```bash
./run.sh codex backend_tz_from_template.md
```

### Шаг 7. Смотреть, что produced

Нужно проверять:

- обновлены ли `docs/architecture.md`, `docs/adr/ADR-*.md`, `openapi.yaml`, `docs/dev-environment.md`, `docs/schema-decisions.md`, `docs/test-matrix.md`, `docs/final-review.md`;
- появились ли CR/ADR при конфликтах;
- появились ли реальные backend-code changes;
- появились ли tests/migrations;
- есть ли blocker findings от Gatekeeper.

## 14. Что шаблон уже умеет хорошо

Сильные стороны текущей версии:

- роли уже разделены достаточно четко;
- есть отдельный владелец локальной dev-среды и startup flow;
- есть базовый orchestration pipeline;
- есть skill-driven formalization для ADR/CR/DB review;
- есть `run.sh`;
- есть `verify`;
- добавлено backend-first правило;
- есть защита от "завершили только документами".

## 15. Текущие ограничения шаблона

Важно понимать и слабые стороны.

### 1. `verify` пока шаблонный, а не продуктовый

Сейчас он не проверяет:

- наличие `src/`;
- наличие `tests/`;
- наличие миграций;
- lint;
- unit/integration test status;
- OpenAPI consistency;
- alembic health;
- runtime readiness.

### 2. `project-stack.toml` поддерживается вручную

Теперь стек задается machine-readable профилем, но этот файл нужно держать в актуальном состоянии.

- если реальный runtime уже поменяли, а `project-stack.toml` нет, агенты будут опираться на устаревшие assumptions;
- профиль пока не строится автоматически из `pyproject.toml`, compose-файлов или исходников;
- для другого web stack одного редактирования `project-stack.toml` всё равно недостаточно: template останется FastAPI-only без адаптации ролей.

### 3. Нет semantic-validation фазовых артефактов

Теперь список обязательных файлов задан явно, но `verify` пока проверяет в основном наличие и базовую структуру артефактов, а не качество их содержимого.

### 4. `backend-bootstrap` создает skeleton, но не доменную реализацию

Теперь шаблон умеет создавать стартовый backend foundation layer, но это не заменяет продуктовую разработку.

- skill помогает создать структуру проекта;
- skill не проектирует бизнес-модель сам по себе;
- после bootstrap всё ещё нужны API/DB/Worker/Tests итерации по реальным требованиям.

## 16. Как мысленно представить всю систему целиком

Самая полезная модель такая:

### Слой 1. Конфигурация

`.codex/config.toml`

Определяет:

- multi-agent включен;
- сколько агентов можно запускать;
- какие роли зарегистрированы.

### Слой 2. Роли

`.codex/agents/*.toml`

Определяют:

- кто за что отвечает;
- что запрещено;
- как выглядит результат.

### Слой 3. Навыки

`.codex/skills/*`

Определяют:

- как выполнять сложные типовые подзадачи повторяемо.

### Слой 4. Пользовательский вход

`TZ_TEMPLATE.md` или конкретное ТЗ

Это источник задачи:

- что именно нужно построить;
- какие условия успеха;
- где требования.

### Слой 5. Оркестрация

`run.sh codex` + prompt + Orchestrator

Это механизм исполнения:

- кто стартует первым;
- кто идет параллельно;
- кто кого ждёт;
- где нужен CR;
- когда повторять цикл.

### Слой 6. Контроль качества

`Devenv` + `Tests` + `Monitor` + review-агенты + `Gatekeeper` + `verify.sh`

Это слой проверки:

- что выполнено;
- что сломано;
- есть ли blocker;
- можно ли завершать workflow.

## 17. Если описать процесс одной короткой схемой

```text
User -> run.sh -> codex -> Orchestrator
Orchestrator -> Architect
Orchestrator -> DB + API
Orchestrator -> CR flow (если нужен)
Orchestrator -> Devenv -> Worker
Orchestrator -> Tests + Monitor
Orchestrator -> Security Reviewer + Consistency Reviewer + Performance Reviewer
Orchestrator -> Gatekeeper
Gatekeeper blocker? -> назад в remediation loop
No blocker + verify ok + checklist done + code changed -> finish
```

## 18. Практический смысл шаблона

Шаблон полезен не потому, что "несколько агентов красивее одного".

Он полезен потому, что:

- разделяет ответственность;
- уменьшает смешивание архитектуры, API, DB и implementation в одной голове;
- делает конфликты явными;
- заставляет оформлять change requests;
- облегчает review;
- дает повторяемый workflow между проектами.

Если совсем коротко:

этот репозиторий — это не backend, а operating system для управляемой multi-agent разработки backend-проекта.

## 19. Что читать в первую очередь, если хочешь быстро освоиться

Порядок чтения:

1. `README.md`
2. `.codex/config.toml`
3. `.codex/agents/orchestrator.toml`
4. `.codex/agents/worker.toml`
5. `run.sh`
6. `scripts/verify.sh`
7. `TZ_TEMPLATE.md`
8. `.codex/skills/*`

Если читать именно в таком порядке, структура становится понятной гораздо быстрее.

## 20. Итог

В этом шаблоне:

- `README` объясняет правила;
- `TZ_TEMPLATE` задает проектную задачу;
- `.codex/config.toml` включает multi-agent и регистрирует роли;
- agent TOML задают поведение ролей;
- skills стандартизируют узкие процессы;
- `run.sh` запускает workflow;
- `verify.sh` проверяет целостность шаблона;
- Orchestrator запускает и координирует остальные роли;
- Devenv готовит локальную среду и при необходимости поднимает сервисы/API;
- Worker должен дойти до реального backend-кода;
- Tests, Monitor, review-агенты и Gatekeeper замыкают качество и stop conditions.

Если нужно понять систему в одной фразе:

это шаблон управления FastAPI backend-разработкой через orchestrated multi-agent pipeline, а не просто набор markdown-файлов и не просто launcher script.
