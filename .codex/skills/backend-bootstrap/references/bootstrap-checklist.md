# Bootstrap Checklist

Go through this checklist before considering bootstrap complete.

## Runtime Skeleton

- There is a root package compatible with `api_entrypoint` from `project-stack.toml`.
- There is a runnable ASGI app entrypoint.
- There is router registration.
- There are clear places for `services`, `repositories`, `db`, `di`, `messaging`.

## Cross-Cutting Foundation

- There is a custom exception layer.
- There is one unified API handler mapping for app errors.
- There is a place for stable `error codes`.
- There is a base config/settings layer.
- Settings are read through `pydantic-settings`, not from hardcoded configs.
- Public error messages are safe and do not contain secrets/PII.

## Dev/Test Foundation

- There are reproducible dev entrypoints or they are explicitly documented.
- There is a test skeleton (`tests/`, `conftest.py`, at least a base structure).
- Devenv can understand how to start the stack and API.
- There are `.env.example` and `.gitignore` to prevent committing `.env`.

## Boundaries

- Bootstrap did not invent an unapproved API contract.
- Bootstrap did not create an invented DB schema.
- Bootstrap did not substitute itself for an architecture decision.
- Repositories do not control `commit` / `rollback` and do not contain business logic.
- Services own business operations and the transaction boundary.
- Service and repository classes use the `Service` and `Repository` suffixes.
- Public interfaces are typed.
- The next task owner is clear: usually `worker`, `db`, `api`, or `devenv`.
