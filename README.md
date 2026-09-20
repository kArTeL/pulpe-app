# pulpe-app

App de catálogo e inventario para pulperías y minisúper.

Flutter 3.5+ · Riverpod · http

## Arranque

Primero levantá el backend (repo `pulpe-api`), después:

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

En el emulador de Android, `localhost` del host es `10.0.2.2`:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

## Pantallas

- **Productos** — listado con scroll infinito, pull to refresh, y estados de carga, vacío y error.
- **Detalle** — precio, categoría, existencias y descripción.

## Convenciones

La API habla **snake_case**; Dart habla camelCase. La traducción ocurre en dos lugares y solo dos:
los query params en `*_repository.dart` y los `fromJson` en `lib/models/`.

El detalle completo está en [AGENTS.md](./AGENTS.md), que es también lo que leen los agentes de código.
