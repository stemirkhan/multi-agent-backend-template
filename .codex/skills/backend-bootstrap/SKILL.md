---
name: backend-bootstrap
description: Create the initial FastAPI backend skeleton from `project-stack.toml` when the repository lacks runnable app structure, dev entrypoints, test scaffolding, or shared layers such as custom exceptions, DI, messaging, and DB bootstrap. Use before feature implementation when Worker or Orchestrator need a minimal but coherent project layout instead of building business logic in an empty repo.
---

# Backend Bootstrap

## Overview

Create a minimal, runnable backend foundation for this template's FastAPI stack. The goal is to give Worker, Devenv, Tests, and Monitor a coherent starting structure so feature work does not begin from an empty repository or an ad-hoc layout.

## Use This Skill When

- the repository still has no clear runtime skeleton for `FastAPI`;
- there is no ASGI entrypoint, no base layout for `api`, `services`, `repositories`, `db`, `di`, `messaging`, `tests`;
- there are no reproducible dev entrypoints, so Devenv cannot bring up the environment cleanly;
- the custom exception layer is missing, and service code would otherwise start throwing `HTTPException` or raw infra errors;
- Orchestrator determines that a foundation layer is needed before feature implementation.

## Do Not Use This Skill When

- the repository already has a coherent skeleton and only needs feature-level implementation;
- the task is limited to API/DB/ADR contracts and code foundation is not the blocker;
- the next step should be a Change Request or an architecture decision, not scaffolding;
- the user only asked for review or a narrow fix.

## Workflow

1. Confirm trigger and preconditions
- Read `project-stack.toml`.
- Continue only if the profile is compatible with this template (`framework = "fastapi"`).
- Quickly inspect the current project tree. If a runnable skeleton already exists, stop and briefly return `bootstrap not required`.
- If a CR/ADR is needed before bootstrap, escalate that and do not replace an architecture decision with generated structure.

2. Load only the references you need
- For target structure and minimal files, use `references/project-layout.md`.
- For the custom exception layer and global handlers, use `references/exception-layer.md`.
- For env/settings and local security, use `references/settings-and-secrets.md`.
- For service/repository boundaries, use `references/service-repository-boundaries.md`.
- For base formatter/linter/type-check defaults, use `references/code-quality.md`.
- Before finishing, cross-check against `references/bootstrap-checklist.md`.

3. Bootstrap the minimal runtime structure
- Create or normalize the layout for `app`, `api`, `core`, `di`, `db`, `services`, `repositories`, `messaging`, `tests`, `scripts`.
- Add the ASGI entrypoint, router registration, settings/config skeleton, DB session bootstrap, DI wiring, and messaging/broker placeholder.
- If foundation is entirely missing, create `.env.example`, `.gitignore`, a minimal tool-configuration skeleton, and a `pydantic-settings`-based settings layer.
- Build extension points, not fake business logic.

4. Bootstrap cross-cutting layers
- Create a separate custom exception layer and one unified API error-handler surface.
- Prefer app-level exceptions instead of direct `HTTPException` in `services` and `repositories`.
- Add a place for stable `error codes` so API and Tests can rely on one contract.

5. Bootstrap dev and test entrypoints
- Make sure Devenv can reproducibly bring up the stack: use existing project entrypoints or create minimal `dev-up` / `dev-api` entrypoints.
- Create a safe local bootstrap: env vars only, no secrets in code, and no committed `.env`.
- Create a test skeleton sufficient for smoke/unit/integration base, but do not pretend to cover nonexistent features.

6. Sync docs and handoff
- If the startup flow changed, update `docs/dev-environment.md`.
- If bootstrap introduces important constraints in runtime structure, record them for Architect/Orchestrator.
- Return the list of created files, blockers, and the next owner.

## Output Rules

- Follow `project-stack.toml`; do not introduce another stack or layout without an explicit reason.
- Create runnable scaffolding, but do not invent a domain model, endpoints, DB schema, or business rules.
- If a stub is needed, make it minimal and extensible.
- For the error layer, keep one clear taxonomy, not 20 tiny exceptions with no value.
- Internal layers must not throw `HTTPException` or raw library exceptions outward; use app-level errors.
- Services own business logic and transaction/UoW control; repositories remain a data-access layer without `commit`/`rollback`.
- Public services, repositories, DTOs, and settings must be typed.
- Do not substitute yourself for `API`, `DB`, or `Architect`.

## Quality Checklist

- Is there a runnable ASGI entrypoint?
- Are there clear places for `api`, `services`, `repositories`, `db`, `di`, `messaging`, `tests`?
- Is there a separate custom exception layer and global handler mapping?
- Are `.env.example`, `.gitignore`, and a `pydantic-settings` settings layer present?
- Is the `Service`/`Repository` boundary respected, and is transaction ownership clear?
- Are there minimal code-quality defaults for formatter/linter/type hints?
- Can Devenv reproducibly start the API after bootstrap?
- Can Worker continue feature work without reinventing the foundation?
