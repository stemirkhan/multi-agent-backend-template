# Code Quality Defaults

Use this reference when bootstrap creates the project's base toolchain.

## Hard defaults

- The project must have an autoformatter.
- The project must have a linter.
- Public interfaces must have type hints.
- Wildcard imports and obvious dead code are forbidden.

## Preferred Minimum Set

- formatter: `ruff format`
- linter: `ruff`
- tests: `pytest`
- type checking: `mypy` or `pyright`

## Minimum Bootstrap Responsibilities

- if tool configuration is missing, create minimal configuration in `pyproject.toml` or a compatible file;
- do not introduce an overly strict mode that immediately breaks an empty skeleton;
- make sure the next iterative step can run format/lint/test without rewriting the entire foundation.
