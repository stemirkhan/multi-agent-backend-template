# Bootstrap Checklist

Пройди этот checklist перед тем, как считать bootstrap завершенным.

## Runtime skeleton

- Есть root package, совместимый с `api_entrypoint` из `project-stack.toml`.
- Есть runnable ASGI app entrypoint.
- Есть router registration.
- Есть места для `services`, `repositories`, `db`, `di`, `messaging`.

## Cross-cutting foundation

- Есть слой кастомных исключений.
- Есть единый API handler mapping для app errors.
- Есть место для стабильных `error codes`.
- Есть базовый config/settings слой.
- Settings читаются через `pydantic-settings`, а не из захардкоженных конфигов.
- Публичные error messages безопасны и не содержат secrets/PII.

## Dev/Test foundation

- Есть reproducible dev entrypoint'ы или они явно задокументированы.
- Есть тестовый skeleton (`tests/`, `conftest.py`, хотя бы базовая структура).
- Devenv может понять, чем поднимать стек и API.
- Есть `.env.example` и `.gitignore`, защищающий от коммита `.env`.

## Boundaries

- Bootstrap не придумал неутвержденный API contract.
- Bootstrap не создал выдуманную схему БД.
- Bootstrap не подменил собой архитектурное решение.
- Репозитории не управляют `commit` / `rollback` и не содержат бизнес-логики.
- Сервисы владеют бизнес-операциями и транзакционной границей.
- Классы сервисов и репозиториев названы с суффиксами `Service` и `Repository`.
- Публичные интерфейсы типизированы.
- Следующий владелец задачи понятен: обычно `worker`, `db`, `api` или `devenv`.
