# Service Repository Boundaries

Use this reference when bootstrap creates the foundation for `services/` and `repositories/`.

## Hard defaults

- Business logic lives in `Service`.
- A repository handles data access only.
- A repository does not control transactions and does not do `commit` / `rollback`.
- The service or `UoW` owns the transaction boundary.
- Service classes end with `Service`.
- Repository classes end with `Repository`.

## Typed inputs

- Public service methods should accept typed inputs.
- For commands/create/update, prefer DTOs or equivalent typed models.
- Repositories should not accept raw unstructured `dict` when typed inputs can be used.

## What To Avoid

- business rules in the repository;
- direct `HTTPException` from a service;
- mixing orchestration and data access in one class;
- dead code and unused public methods.
