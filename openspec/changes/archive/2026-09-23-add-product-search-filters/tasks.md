## 1. Repository

- [x] 1.1 Add optional `search` and `category` params to `ProductsRepository.list()`, included in the query map only when non-null/non-empty (trimmed for search), keys `search`/`category`.

## 2. State / Provider

- [x] 2.1 Add `search` and `category` fields to `ProductsState`.
- [x] 2.2 Add `ProductsNotifier.setSearch(String value)` and `ProductsNotifier.setCategory(String? slug)` that update filter state and reload from page 1, replacing accumulated products.
- [x] 2.3 Ensure `loadMore()` passes the current `search`/`category` filter state to `repo.list()`.
- [x] 2.4 Add a `categoriesProvider` (`FutureProvider<List<Category>>`) backed by `ProductsRepository.categories()`.

## 3. UI

- [x] 3.1 Add a debounced search `TextField` to `ProductsListScreen` (e.g. in the `AppBar` or as a header above the list) that calls `setSearch` after ~400ms of inactivity, using a `Timer` from `dart:async`.
- [x] 3.2 Add a category filter chip row (including an "All" chip) above the list, backed by `categoriesProvider`, that calls `setCategory`.
- [x] 3.3 Verify the existing loading/data/empty/error-with-retry states still render correctly with filters applied (empty filtered result reuses `_EmptyState`; retry reuses current filters).

## 4. Tests

- [x] 4.1 Repository test: `search`/`category` are added to the query map only when provided/non-empty, with correct snake_case keys.
- [x] 4.2 Screen/provider test: changing search text resets to page 1 and reloads with the new `search` param.
- [x] 4.3 Screen/provider test: selecting a category resets to page 1 and reloads with the new `category` param; selecting "All" clears it.
- [x] 4.4 Screen/provider test: an empty filtered result renders the existing empty state.

## 5. Documentation

- [x] 5.1 Update `AGENTS.md`'s "API contract" query-param table to document `search` and `category`.

## 6. Wrap-up

- [x] 6.1 Run `flutter analyze && flutter test` and fix any issues.
- [x] 6.2 Archive the openspec change (`openspec archive`).
