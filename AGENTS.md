# AGENTS.md — pulpe-app

Instructions for any code agent working in this repo.
If anything here contradicts what you think is the "normal" Flutter convention, this file wins.

## What this is

Catalog and inventory app for corner stores and mini markets. Flutter 3.5+, Riverpod, `http`.
Consumes the API from the `pulpe-api` repo.

## Commands

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:3000
flutter analyze
flutter test
```

On the Android emulator use `http://10.0.2.2:3000` instead of `localhost`.

Before considering any change done: `flutter analyze && flutter test`.

## API contract

**The backend speaks snake_case. Dart speaks camelCase. The translation happens in exactly one place.**

- **Query params:** built only in `lib/features/*/\*_repository.dart`, with keys in snake_case (`per_page`, not `perPage`).
- **Responses:** the snake_case → camelCase mapping lives only in the `fromJson`s in `lib/models/`.
- Outside those two places, the rest of the app uses normal Dart camelCase.

If you send `sortBy` where the API expects `sort_by`, the backend responds **422** and the screen stays empty.
No compiler catches this, on either side. The current parameter table is in `pulpe-api`'s `AGENTS.md`.

`GET /products` query params (all optional):

| Param      | Type   | Meaning                                                        |
|------------|--------|------------------------------------------------------------------|
| `page`     | int    | Page number, 1-based.                                          |
| `per_page` | int    | Items per page.                                                |
| `search`   | string | Case-insensitive partial match against product name or description. |
| `category` | string | Filters by category slug.                                      |

Error format returned by the API:

```json
{ "error": { "code": "invalid_params", "message": "…", "details": {} } }
```

`ApiClient` already translates it to `ApiException`; network errors come out as `NetworkException`.

## Code conventions

- **Language:** domain identifiers are in English (`product`, `price`, `stock`). Flutter symbols stay in English (`build`, `initState`, `ListView`).
- **Prices:** arrive as integers in colón cents. ALWAYS format with `Format.price()`, never divide by 100 inside a widget.
- **State:** Riverpod. One provider per resource, in its feature's repository file. No `setState` for data coming from the API.
- **Structure:** one folder per feature in `lib/features/`, with its `_repository.dart` and its screens. Shared code goes in `lib/core/`.
- **Networking:** all calls go through `ApiClient`. Don't use `http` directly in a widget or a screen.
- **Widgets:** private ones live in the same file, prefixed with `_`. `const` constructors wherever possible.
- **Configuration:** the base URL is read with `String.fromEnvironment`. Never hardcode a host in the code.

## Screen states

Every screen that loads data has to handle all four cases: **loading**, **with data**, **empty** and **error with a retry button**.
`ProductsListScreen` is the reference; copy that pattern.

## What NOT to do

- Don't add dependencies on external services (Firebase, push providers, analytics, cloud storage). The project runs entirely locally, on purpose.
- Don't change the `fromJson`s to accept camelCase: the problem would be in the contract, not in the parsing.
- Don't delete or skip a test to make the suite pass.
