# Code Quality Defaults

Используй этот reference, когда bootstrap создает базовый toolchain проекта.

## Hard defaults

- В проекте должен быть автоформатер.
- В проекте должен быть линтер.
- Публичные интерфейсы должны иметь type hints.
- Запрещены wildcard imports и очевидный мертвый код.

## Предпочтительный минимальный набор

- formatter: `ruff format`
- linter: `ruff`
- tests: `pytest`
- type checking: `mypy` или `pyright`

## Что bootstrap должен сделать минимум

- если tool configuration отсутствует, создать минимальную конфигурацию в `pyproject.toml` или совместимом файле;
- не вводить избыточно строгий режим, который сразу ломает пустой skeleton;
- сделать так, чтобы следующий итеративный шаг мог запускать format/lint/test без полного переписывания foundation.
