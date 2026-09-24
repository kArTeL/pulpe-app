## Why

Shoppers currently can only browse the full product catalog page by page; there is no way to search by name or narrow results to a category. As the catalog grows, finding a specific product requires scrolling through an unbounded list. The backend team is building a `GET /products/search` endpoint (companion task in `pulpe-api`) that supports free-text search, category filtering, and per-category match counts — this change adds the Flutter screen that consumes it.

## What Changes

- Add a `CategoryCount` model mapping the API's `category_counts` entries (`category` + `count`).
- Add a `ProductSearchResult` model (sibling to `PagedResult`, not a widening of it) carrying `items`, `total`, `page`, `perPage`, `hasNext`, and `categoryCounts`.
- Add `ProductsRepository.search({ q, category, page, perPage })`, calling `GET /products/search` with snake_case query params (`q`, `category`, `page`, `per_page`), omitting `q`/`category` when empty.
- Add a new `ProductSearchScreen` reachable from `ProductsListScreen`'s app bar, with:
  - A debounced (300-400ms) free-text search field.
  - A category filter control populated from `ProductsRepository.categories()`, showing each category's live match count from `category_counts`.
  - Infinite-scroll pagination at 15 items per page, matching `ProductsListScreen`'s pattern.
  - All four screen states: loading, with data, empty ("No products match your search"), and error with a retry button.
- Add a Riverpod `AsyncNotifier`-based provider for search state, keyed on the current `q`/`category` so changing either resets to page 1.

## Capabilities

### New Capabilities
- `product-search`: free-text and category-filtered product search screen, with paginated results and per-category match counts to drive the filter UI.

### Modified Capabilities
(none — this is an additive screen; no existing spec requirements change)

## Impact

- New files: `lib/models/category_count.dart`, `lib/models/product_search_result.dart`, `lib/features/products/product_search_screen.dart`.
- Modified files: `lib/features/products/products_repository.dart` (new `search()` method + provider/notifier), `lib/features/products/products_list_screen.dart` (app bar search action).
- New tests: `test/product_search_test.dart` (or similar) covering `CategoryCount.fromJson`/`ProductSearchResult.fromJson` and `ProductsRepository.search()` query param construction.
- Depends on the `GET /products/search` endpoint contract (fixed, shared with the parallel `pulpe-api` task); this screen is built directly against that contract without waiting on the live backend.
- No changes to existing `fromJson`s, no new dependencies, no hardcoded host.
