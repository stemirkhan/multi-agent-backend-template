# Bootstrap Project Layout

Используй этот reference, когда нужно быстро создать минимальный, но coherent skeleton под stack profile шаблона.

## Принципы

- Следуй `project-stack.toml`.
- Если `api_entrypoint` указывает на `app.main:app`, дефолтный корень layout — `app/`.
- Если в репозитории уже есть устоявшийся root package и он совместим с entrypoint'ом, не ломай его только ради шаблонной красоты.
- Создавай extension points, а не фальшивую продуктовую реализацию.

## Минимальная структура по умолчанию

```text
.gitignore
.env.example
pyproject.toml
alembic.ini
alembic/
  env.py
  versions/
app/
  __init__.py
  main.py
  api/
    __init__.py
    error_handlers.py
    v1/
      __init__.py
      router.py
  core/
    __init__.py
    config.py
    logging.py
  errors/
    __init__.py
    base.py
    codes.py
    domain.py
    infrastructure.py
  di/
    __init__.py
    providers.py
  db/
    __init__.py
    base.py
    models/
      __init__.py
    session.py
  services/
    __init__.py
  repositories/
    __init__.py
  messaging/
    __init__.py
    broker.py
    consumers/
      __init__.py
tests/
  __init__.py
  conftest.py
  unit/
    __init__.py
  integration/
    __init__.py
scripts/
  dev-up.sh
  dev-api.sh
```

## Что должно появиться минимум

- `main.py` с FastAPI app и подключением router/handlers.
- базовый config/settings слой на `pydantic-settings`.
- база для DI wiring.
- база для SQLAlchemy session/bootstrap.
- база для FastStream broker/consumer wiring.
- слой ошибок и единая точка exception handlers.
- `.env.example` и `.gitignore`, чтобы локальные секреты не попадали в git.
- минимальный tool configuration layer (`ruff format` / `ruff`, `pytest`, типизация публичных интерфейсов).
- тестовый skeleton, достаточный для smoke/integration foundation.
- reproducible entrypoint'ы для dev-среды и локального API, если их ещё не было.

## Чего не делать

- не придумывать продуктовые endpoint'ы только ради наполнения router;
- не создавать выдуманные SQLAlchemy модели без контракта DB;
- не прошивать бизнес-правила в bootstrap;
- не хранить секреты в коде, `pyproject.toml` или коммитнутом `.env`;
- не плодить каталоги "на всякий случай", если они не несут ownership-смысла.
