# Multi-Agent Workflow — Beauty Platform SaaS (MVP)

Этот документ описывает роли агентов, порядок работы и правила взаимодействия.

---

# Общая цель

Собрать backend MVP строго по ТЗ:

- Контракты стабильны
- БД консистентна
- Тесты проходят
- Acceptance Checklist закрыт
- Нет security/blocker-рисков

---

# Роли агентов

## Orchestrator
Управляет фазами и порядком выполнения.
Не пишет код.
Не меняет схемы.
Решает, кто запускается следующим.

---

## Architect
Фиксирует архитектурные решения как контракт:

- Очередь: Redis Streams
- Кэш каталога: Redis TTL=60s
- Мультитенантность = multi-city (НЕ security boundary)
- Деньги: price_minor (int)
- Soft delete через deleted_at

Результат → docs/architecture.md

---

## DB
Владелец схемы БД и миграций.

- SQLAlchemy 2.x
- Alembic forward-only
- Индексы строго по ТЗ
- UUID v4
- created_at / updated_at обязательны

Не меняет API без change request.

---

## API
Владелец контрактов.

- OpenAPI /api/v1
- Pydantic схемы
- Единый формат ошибок
- Idempotency policy (Redis, TTL=24h)

Не меняет БД напрямую.

---

## Worker
Пишет реализацию.

- Сервисы
- Репозитории
- RBAC + ownership
- Кэш каталога
- Redis Streams consumer

Следует контрактам API/DB/Architect.

---

## Tests
Пишет:

- Unit тесты бизнес-логики
- Integration тесты API + Postgres + Redis
- Contract тесты (схемы/ошибки)
- Матрицу доступов

Не переписывает прод-код без причины.

---

## Reviewer (read-only)
Ищет:

- Broken Access Control
- Гонки транзакций
- Идемпотентность
- N+1
- Отсутствие индексов
- Утечки секретов

Не меняет код.

---

## Explorer (read-only)
Читает код/ТЗ.
Строит карту проекта.
Ищет противоречия.

---

## Monitor (read-only)

Запускает единый verify entrypoint:

- `./scripts/verify.sh`
- `make verify`
- `task verify`
- fallback: команды из раздела "How to test" в README

Если нужны контейнеры — предпочитает Podman, если проект не требует `docker compose` явно.

Не меняет код.

---

# Workflow (порядок фаз)

Phase 1 — Архитектура  
Architect фиксирует решения.

Phase 2 — Контракты  
DB и API запускаются параллельно.  
Orchestrator проверяет совместимость.

Phase 3 — Реализация  
Worker реализует фичи.

Phase 4 — Тестирование  
Tests пишет тесты.  
Monitor запускает verify entrypoint и даёт сводку.

Phase 5 — Ревью  
Reviewer ищет блокеры.  
Если есть — возврат к соответствующему агенту.

Workflow завершён только когда:

- Все тесты зелёные
- Нет blocker issues
- Acceptance Checklist закрыт

---

# Правила взаимодействия

1. Контракты нельзя менять без change request.
2. DB не меняет API.
3. API не меняет DB.
4. Worker не меняет архитектурные решения.
5. Reviewer и Monitor — read-only.
6. Все конфликты фиксируются явно.

---

# Change Request Protocol

Если агенту нужно изменить контракт:

1. Оформить:
   - Что нужно изменить
   - Почему
   - Impact
2. Передать Orchestrator.
3. Orchestrator решает, кого перезапустить.

---

# Acceptance Condition

Проект считается готовым если:

- Все endpoint’ы v1 реализованы
- RBAC покрыт тестами
- Миграции применяются на чистой БД
- Каталог корректно фильтрует/сортирует
- Идемпотентность работает
- Аналитика асинхронна
- Логи/метрики подключены
- Тесты зелёные
- Нет blocker issues
