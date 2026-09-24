## Why

Right now the only way to find a product is to scroll the full catalog. As the number of SKUs grows, that stops working for a corner-store owner looking for one specific item. The backend is adding `GET /products/search` (parallel `pulpe-api` change, same contract) so the app needs a screen that searches by free text and filters by category.

## What Changes

- Add a "Search products" entry point from the products list.
- Add a search bar with debounced free-text input.
- Add a category filter sourced from `GET /categories` (no hardcoded category list).
- Add paginated, infinite-scroll results at a fixed 15 items per page (server-controlled `per_page`), reusing the existing `ProductsListScreen` loading/data/empty/error-with-retry convention.
- Add a `search` repository method on `ProductsRepository` that calls `GET /products/search` with `q`, `category`, `page`.

## Capabilities

### New Capabilities
- `product-search`: free-text + category product search with paginated results, backed by `GET /products/search`.

### Modified Capabilities
(none — this adds a new capability; it does not change the requirements of the existing product listing.)

## Impact

- Affected code: `lib/features/products/products_repository.dart` (new `search` method), a new search screen + notifier under `lib/features/products/`, `lib/main.dart` (entry point to the new screen).
- Affected models: none. Reuses `Product`, `Category`, `PagedResult` as-is — the search response is the identical envelope already used by `GET /products`.
- Affected API: consumes `GET /products/search` (implemented in a parallel `pulpe-api` change against the same contract — params and response shape are fixed, not renegotiated here).
- No new dependencies: debouncing is implemented with `dart:async`'s `Timer`, already implicitly available via the Dart SDK.
