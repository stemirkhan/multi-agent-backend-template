# Dev Environment
Status: template
Owner: Devenv
Phase: 3

Этот файл обязателен для Phase 3.
Перед закрытием фазы зафиксируй воспроизводимый локальный startup flow и обнови `Status:`.

## 0. Dependency Bootstrap
- Command:
- Local venv / environment path:
- Package manager / manifest:

## 1. Required Services
- Container runtime: `podman`
- Compose runner: `podman-compose`
- Service:
- Purpose:
- Start command:

## 2. Environment Files And Variables
- File:
- Required vars:
- Secret source / placeholder:

## 3. API Startup
- Command (usually FastAPI/ASGI, e.g. `uvicorn <module>:app --reload`):
- Working directory:
- Base URL:
- Health endpoint:

## 4. Start / Stop / Reset
- Start:
- Stop:
- Reset:

## 5. Verification
- How to confirm services are up:
- How to confirm API is reachable:
- Known limitations:

## 6. Current Blockers
- Blocker:
