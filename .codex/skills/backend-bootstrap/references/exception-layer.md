# Exception Layer

Use this reference when bootstrap creates the shared custom exception layer for a FastAPI backend.

## Goal

Make sure that:

- `services` and `repositories` do not throw `HTTPException` directly;
- API has a stable error contract;
- Tests can validate string `error codes`;
- infrastructure failures do not leak into the HTTP layer without mapping;
- public errors do not expose secrets, PII, or internal technical details.

## Minimum File Set

```text
app/errors/
  base.py
  codes.py
  domain.py
  infrastructure.py
app/api/error_handlers.py
```

## Recommended Minimum Exception Set

- `AppError`
- `ValidationError`
- `NotFoundError`
- `ConflictError`
- `AccessDeniedError`
- `InfrastructureError`
- `ExternalServiceError`

Do not build a complex hierarchy without a clear benefit.

## Layer Rules

- All application errors inherit from `AppError`.
- Every app-level error has `code`, `message`, `details`.
- `HTTPException` is acceptable only at the outer API edge when a direct FastAPI case is actually needed.
- Internal layers prefer `AppError` and its subtypes.
- Every publicly observable exception must have a stable string `code`.
- Technical details and `cause` stay in internal logs/traces, not in the user-facing `message`.
- API handlers must map app-level errors into one unified response shape.
- Error logging happens once at the application boundary.

## Recommended Response Shape

```json
{
  "error": {
    "code": "resource_not_found",
    "message": "Salon not found",
    "details": {}
  }
}
```

## Minimum Mapping

- `ValidationError` -> `400`
- `AccessDeniedError` -> `403`
- `NotFoundError` -> `404`
- `ConflictError` -> `409`
- `InfrastructureError` / `ExternalServiceError` -> `503`
- unexpected error -> `500` via a generic handler without leaking internal details

## What To Avoid

- throwing ORM/driver exceptions directly outward;
- putting secrets, DSNs, tokens, or PII into `message` and `details`;
- mixing domain errors and transport concerns in the same class;
- making error codes unstable or derived from error text;
- building bootstrap around one `Exception` catch-all without app-specific taxonomy.
