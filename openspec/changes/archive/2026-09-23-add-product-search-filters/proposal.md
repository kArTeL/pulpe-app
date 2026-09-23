## Why

The products listing screen supports pagination and infinite scroll but has no way to narrow the list down. With a growing catalog, users need to find a specific product by name/description or restrict the list to one category instead of scrolling through everything.

## What Changes

- Add a debounced search text field to `ProductsListScreen` that filters products by a case-insensitive partial match against name or description, via the backend's new `search` query param.
- Add a category filter (chip row) to `ProductsListScreen`, sourced from `GET /categories`, letting the user pick one category or clear it back to "all", via the backend's new `category` query param.
- Extend `ProductsRepository.list()` to accept optional `search` and `category` params, sent in snake_case and only included when non-empty/non-null.
- Changing search text or the category filter resets the listing to page 1 and reloads; existing pagination/infinite-scroll behavior is preserved for the filtered result set.
- An empty filtered result reuses the screen's existing empty state (no new UI state introduced).

## Capabilities

### New Capabilities
- `product-search-filter`: search box and category filter on the products listing screen, composed with existing pagination.

### Modified Capabilities
(none — no existing specs in this repo; this is the first spec-driven change)

## Impact

- `lib/features/products/products_repository.dart`: `list()` gains optional `search`/`category` params.
- `lib/features/products/products_list_screen.dart`: adds search field + category chip row UI.
- Riverpod state backing `ProductsListScreen` (`ProductsState`/`ProductsNotifier`) gains search/category fields and reset-on-change behavior.
- `AGENTS.md`: query-param table gets `search` and `category` entries.
- Tests: repository query-building tests and screen filtering/search behavior tests.
- No backend changes in this repo; depends on `pulpe-api`'s `GET /products` accepting the new optional `search`/`category` params (contract already fixed, built in parallel).
