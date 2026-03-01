# Bootstrap Project Layout

Use this reference when you need to quickly create a minimal but coherent skeleton for the template's stack profile.

## Principles

- Follow `project-stack.toml`.
- If `api_entrypoint` points to `app.main:app`, the default layout root is `app/`.
- If the repository already has an established root package compatible with the entrypoint, do not break it just for template aesthetics.
- Create extension points, not fake product implementation.

## Default Minimal Structure

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

## Minimum Required Output

- `main.py` with the FastAPI app and router/handler registration.
- a base config/settings layer using `pydantic-settings`.
- a base for DI wiring.
- a base for SQLAlchemy session/bootstrap.
- a base for FastStream broker/consumer wiring.
- the error layer and one unified exception-handler entrypoint.
- `.env.example` and `.gitignore` so local secrets do not end up in git.
- a minimal tool-configuration layer (`ruff format` / `ruff`, `pytest`, typed public interfaces).
- a test skeleton sufficient for smoke/integration foundation.
- reproducible entrypoints for the dev environment and local API if they did not exist yet.

## What Not To Do

- do not invent product endpoints just to populate the router;
- do not create invented SQLAlchemy models without a DB contract;
- do not bake business rules into bootstrap;
- do not store secrets in code, `pyproject.toml`, or a committed `.env`;
- do not create directories "just in case" if they do not reflect real ownership boundaries.
