# Exception Layer

Используй этот reference, когда bootstrap создает общий слой кастомных исключений для FastAPI backend.

## Цель

Сделать так, чтобы:

- `services` и `repositories` не бросали `HTTPException` напрямую;
- API имел стабильный error contract;
- Tests могли проверять строковые `error codes`;
- infrastructure failures не протекали в HTTP-слой без маппинга;
- публичные ошибки не раскрывали секреты, PII и внутренние технические детали.

## Минимальный набор файлов

```text
app/errors/
  base.py
  codes.py
  domain.py
  infrastructure.py
app/api/error_handlers.py
```

## Рекомендуемый минимальный набор исключений

- `AppError`
- `ValidationError`
- `NotFoundError`
- `ConflictError`
- `AccessDeniedError`
- `InfrastructureError`
- `ExternalServiceError`

Не нужно строить сложную иерархию без явной пользы.

## Правила слоя

- Все прикладные ошибки наследуются от `AppError`.
- У каждого app-level error есть `code`, `message`, `details`.
- `HTTPException` допустим только на внешнем API-краю, если действительно нужен direct FastAPI case.
- Внутренние слои предпочитают `AppError` и его подтипы.
- У каждого публично наблюдаемого исключения должен быть стабильный строковый `code`.
- Технические детали и `cause` остаются во внутренних логах/trace, а не в пользовательском `message`.
- API handlers должны маппить app-level errors в единый response shape.
- Логирование ошибки выполняется один раз на границе приложения.

## Рекомендуемый response shape

```json
{
  "error": {
    "code": "resource_not_found",
    "message": "Salon not found",
    "details": {}
  }
}
```

## Минимальный mapping

- `ValidationError` -> `400`
- `AccessDeniedError` -> `403`
- `NotFoundError` -> `404`
- `ConflictError` -> `409`
- `InfrastructureError` / `ExternalServiceError` -> `503`
- unexpected error -> `500` через generic handler без утечки внутренних деталей

## Чего избегать

- кидать ORM/driver exceptions прямо наружу;
- кидать секреты, DSN, токены или PII в `message` и `details`;
- смешивать domain errors и transport concerns в одном классе;
- делать error codes нестабильными или вычисляемыми от текста ошибки;
- строить bootstrap на одном `Exception` catch-all без app-specific taxonomy.
