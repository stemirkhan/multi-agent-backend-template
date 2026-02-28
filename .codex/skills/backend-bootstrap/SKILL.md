---
name: backend-bootstrap
description: Create the initial FastAPI backend skeleton from `project-stack.toml` when the repository lacks runnable app structure, dev entrypoints, test scaffolding, or shared layers such as custom exceptions, DI, messaging, and DB bootstrap. Use before feature implementation when Worker or Orchestrator need a minimal but coherent project layout instead of building business logic in an empty repo.
---

# Backend Bootstrap

## Overview

Create a minimal, runnable backend foundation for this template's FastAPI stack. The goal is to give Worker, Devenv, Tests, and Monitor a coherent starting structure so feature work does not begin from an empty repository or an ad-hoc layout.

## Use This Skill When

- репозиторий ещё не имеет понятного runtime skeleton для `FastAPI`;
- нет ASGI entrypoint, базового layout для `api`, `services`, `repositories`, `db`, `di`, `messaging`, `tests`;
- нет reproducible dev entrypoint'ов и без них Devenv не может нормально поднять среду;
- отсутствует слой кастомных исключений и сервисный код иначе начнет бросать `HTTPException` или сырые infra-ошибки;
- Orchestrator понимает, что перед feature implementation сначала нужен foundation layer.

## Do Not Use This Skill When

- в репозитории уже есть coherent skeleton и нужен только feature-level implementation;
- задача ограничена контрактами API/DB/ADR и кодовый foundation не является блокером;
- для продолжения сначала нужен Change Request или архитектурное решение, а не scaffold;
- пользователь просит только review или точечный фикс.

## Workflow

1. Confirm trigger and preconditions
- Прочитай `project-stack.toml`.
- Продолжай только если профиль совместим с этим шаблоном (`framework = "fastapi"`).
- Быстро оцени текущее дерево проекта. Если runnable skeleton уже есть, остановись и коротко верни `bootstrap not required`.
- Если вместо bootstrap сначала нужен CR/ADR, эскалируй это и не подменяй архитектурное решение генерацией структуры.

2. Load only the references you need
- Для целевой структуры и минимальных файлов используй `references/project-layout.md`.
- Для слоя кастомных исключений и global handlers используй `references/exception-layer.md`.
- Для env/settings и локальной безопасности используй `references/settings-and-secrets.md`.
- Для границ между сервисами и репозиториями используй `references/service-repository-boundaries.md`.
- Для базовых formatter/linter/type-check defaults используй `references/code-quality.md`.
- Перед завершением сверься с `references/bootstrap-checklist.md`.

3. Bootstrap the minimal runtime structure
- Создай или нормализуй layout для `app`, `api`, `core`, `di`, `db`, `services`, `repositories`, `messaging`, `tests`, `scripts`.
- Добавь ASGI entrypoint, router registration, settings/config skeleton, db session bootstrap, DI wiring, messaging/broker placeholder.
- Если foundation отсутствует полностью, создай `.env.example`, `.gitignore`, минимальный tool configuration skeleton и слой settings на `pydantic-settings`.
- Делай extension points, а не фальшивую бизнес-логику.

4. Bootstrap cross-cutting layers
- Создай отдельный слой кастомных исключений и единый API error handler surface.
- Предпочитай app-level exceptions вместо прямого `HTTPException` в `services` и `repositories`.
- Добавь место для стабильных `error codes`, чтобы API и Tests могли опираться на один контракт.

5. Bootstrap dev and test entrypoints
- Убедись, что Devenv может воспроизводимо поднимать стек: используй существующие entrypoint'ы проекта или создай минимальные `dev-up` / `dev-api` entrypoint'ы.
- Сделай безопасный локальный bootstrap: только env vars, без секретов в коде и без коммита `.env`.
- Создай тестовый skeleton, достаточный для smoke/unit/integration base, но не имитируй покрытие несуществующих фич.

6. Sync docs and handoff
- Если startup flow изменился, обнови `docs/dev-environment.md`.
- Если bootstrap вносит важные ограничения в runtime structure, зафиксируй это для Architect/Orchestrator.
- Верни список созданных файлов, блокеры и следующего владельца задачи.

## Output Rules

- Следуй `project-stack.toml`; не вводи другой stack или layout без явной причины.
- Создавай runnable scaffold, но не выдумывай предметную модель, endpoint'ы, схему БД или доменные правила.
- Если нужна заготовка, делай её минимальной и расширяемой.
- При bootstrap слоя ошибок держи одну понятную taxonomy, а не 20 мелких исключений без пользы.
- Внутренние слои не должны бросать `HTTPException` и сырые library exceptions наружу; используй app-level errors.
- Сервисы владеют бизнес-логикой и транзакцией/UoW; репозитории остаются слоем доступа к данным без `commit`/`rollback`.
- Публичные сервисы, репозитории, DTO и настройки должны быть типизированы.
- Не подменяй собой `API`, `DB` или `Architect`.

## Quality Checklist

- Есть ли runnable ASGI entrypoint?
- Есть ли понятные места для `api`, `services`, `repositories`, `db`, `di`, `messaging`, `tests`?
- Создан ли отдельный слой кастомных исключений и global handler mapping?
- Есть ли `.env.example`, `.gitignore` и settings layer на `pydantic-settings`?
- Соблюдена ли граница `Service`/`Repository` и ownership транзакций?
- Есть ли минимальные code-quality defaults для formatter/linter/type hints?
- Может ли Devenv воспроизводимо поднять API после bootstrap?
- Может ли Worker продолжать feature work без повторного изобретения foundation?
