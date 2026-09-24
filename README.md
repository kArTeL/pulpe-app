# pulpe-app

Catalog and inventory app for corner stores and mini markets.

Flutter 3.5+ · Riverpod · http

## Getting started

First start the backend (repo `pulpe-api`), then:

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

On the Android emulator, the host's `localhost` is `10.0.2.2`:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

## Screens

- **Products** — listing with infinite scroll, pull to refresh, and loading, empty and error states.
- **Detail** — price, category, stock and description.
- **Search** — free-text and category search over products, with paginated infinite-scroll results.

## Conventions

The API speaks **snake_case**; Dart speaks camelCase. The translation happens in exactly two places:
the query params in `*_repository.dart` and the `fromJson`s in `lib/models/`.

Full details are in [AGENTS.md](./AGENTS.md), which is also what code agents read.
