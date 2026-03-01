# Settings And Secrets

Use this reference when bootstrap creates the config layer and local dev bootstrap.

## Hard defaults

- `.env` is not committed.
- The repository stores only `.env.example`.
- All secrets and DSNs are read through env vars.
- `pydantic-settings` is used to load settings.
- Local environments and tests use synthetic data, not real PII.

## Minimum Output

- `app/core/config.py` or an equivalent settings module.
- `.env.example` with required variables.
- `.gitignore` that excludes `.env`, but does not exclude `.env.example`.

## What `.env.example` Should Contain

- `APP_ENV`
- `APP_HOST`
- `APP_PORT`
- `LOG_LEVEL`
- `POSTGRES_DSN`
- `REDIS_DSN`
- `JWT_SECRET`

Use placeholder values only for local development.

## What Not To Do

- do not store secrets in code, compose files, or a tracked `.env`;
- do not make runtime depend on unvalidated environment variables;
- do not use real user data for local bootstrap.
