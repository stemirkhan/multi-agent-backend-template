# Settings And Secrets

Используй этот reference, когда bootstrap создает config layer и локальный dev bootstrap.

## Hard defaults

- `.env` не коммитится.
- В репозитории хранится только `.env.example`.
- Все секреты и DSN читаются через env vars.
- Для загрузки настроек используется `pydantic-settings`.
- В локальной среде и тестах используются синтетические данные, а не реальные PII.

## Минимальный output

- `app/core/config.py` или эквивалентный settings module.
- `.env.example` с обязательными переменными.
- `.gitignore`, который исключает `.env`, но не исключает `.env.example`.

## Что должно быть в `.env.example`

- `APP_ENV`
- `APP_HOST`
- `APP_PORT`
- `LOG_LEVEL`
- `POSTGRES_DSN`
- `REDIS_DSN`
- `JWT_SECRET`

Добавляй только placeholder values для локальной разработки.

## Чего не делать

- не хранить секреты в коде, compose-файлах или tracked `.env`;
- не делать runtime зависимым от невалидированных переменных окружения;
- не использовать реальные пользовательские данные для локального bootstrap.
