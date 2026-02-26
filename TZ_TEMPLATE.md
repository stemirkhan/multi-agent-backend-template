# ТЗ проекта: <PROJECT_NAME>
Версия: <v1.0>
Дата: <YYYY-MM-DD>
Owner: <NAME/TEAM>

## 1. Цель и границы
### 1.1 Цель MVP
- <Измеримый бизнес-результат 1>
- <Измеримый бизнес-результат 2>

### 1.2 In Scope
- <Что точно входит в MVP>

### 1.3 Out of Scope
- <Что не делаем в MVP>

## 2. Бизнес-сценарии
### US-001: <Название сценария>
- Актор: <кто>
- Предусловия: <что должно быть до старта>
- Шаги: <кратко>
- Результат: <ожидаемый результат>

### US-002: <Название сценария>
- Актор: <кто>
- Предусловия: <...>
- Шаги: <...>
- Результат: <...>

## 3. Глоссарий
- <Термин 1>: <определение>
- <Термин 2>: <определение>

## 4. Функциональные требования (FR)
- FR-001: <требование>, вход: <...>, выход: <...>, ограничения: <...>
- FR-002: <требование>, вход: <...>, выход: <...>, ограничения: <...>

## 5. Нефункциональные требования (NFR)
- NFR-001 (Performance): <p95/p99, SLA/SLO>
- NFR-002 (Security): <auth, RBAC, ownership, secrets>
- NFR-003 (Reliability): <retry, timeout, idempotency>
- NFR-004 (Observability): <логи, метрики, алерты, трассировка>

## 6. Архитектурные решения (ADR-ready)
- Очереди/фоновые задачи: <описание>
- Кэш: ключи, TTL, инвалидация: <описание>
- Границы безопасности: <ownership boundary>
- Транзакционные границы: <где атомарность обязательна>

## 7. Контракт БД
### 7.1 Сущности
- <Entity>: поля (<type>, nullable, default), PK/FK, ограничения

### 7.2 Индексы
- IDX-001: <таблица/поля>, для запроса: <какой>
- IDX-002: <таблица/поля>, для сортировки: <какой>

### 7.3 Политики данных
- Soft delete: <да/нет, как>
- created_at/updated_at: <правило>
- Миграции: forward-only, без правок примененных ревизий

## 8. API контракт v1
### 8.1 Endpoint
- `METHOD /api/v1/<path>`
- Auth: <роль/политика>
- Request schema: <поля>
- Response schema: <поля>
- Errors: <error_code + HTTP status>

### 8.2 Idempotency matrix
- `POST /...`: Idempotency-Key <required|optional>, scope: <...>, TTL: <...>
- `POST /...`: Idempotency-Key <required|optional>, scope: <...>, TTL: <...>

## 9. RBAC и ownership matrix
- Роль `<role_a>`: allow `<endpoint_list>`, deny `<endpoint_list>`
- Роль `<role_b>`: allow `<endpoint_list>`, deny `<endpoint_list>`
- Ownership правило: `<entity_owner_id == user_id>`

## 10. Интеграции и события
- Event: `<name>`, producer: `<service>`, consumer: `<service>`, payload: `<schema>`
- Retry/DLQ policy: <описание>

## 11. Тестовая стратегия
- Unit: <ключевые проверки>
- Integration: <API + DB + cache/queue>
- Contract: <OpenAPI/error format/idempotency>
- Security: <RBAC/ownership/negative tests>
- Acceptance: <E2E критерии>

## 12. План релиза
- Rollout шаги: <1..N>
- Rollback условия: <когда откатываем>
- Rollback шаги: <как откатываем>
- Data backfill (если нужно): <как и когда>

## 13. Acceptance checklist (Definition of Done)
- [ ] Все FR выполнены
- [ ] NFR подтверждены метриками/тестами
- [ ] Миграции применяются на чистой БД
- [ ] RBAC/ownership покрыт тестами
- [ ] Idempotency подтверждена тестами
- [ ] `./scripts/verify.sh` завершился с exit code 0

## 14. Ownership по агентам
- Architect: владеет разделами 5/6 и архитектурными ADR
- DB: владеет разделом 7
- API: владеет разделом 8
- Worker: реализация по контрактам
- Tests: стратегия и тесты из раздела 11
- Reviewer: финальная проверка рисков/безопасности
- Monitor: запуск verify и сводка результатов

## 15. Change Request Protocol
- Что меняем: <контракт/правило/поле/endpoint>
- Почему: <блокер/несовместимость>
- Impact: <API/DB/tests/rollout>
- Совместимость: <backward-compatible yes/no/partial>
- План проверки: <какие проверки должны пройти>
- Ответственный и следующий шаг: <кто делает что>
