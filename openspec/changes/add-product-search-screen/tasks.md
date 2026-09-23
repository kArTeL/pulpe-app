## 1. Models

- [ ] 1.1 Add `lib/models/category_count.dart` with `CategoryCount` (`category`, `count`) and `fromJson` mapping `{"category": {...}, "count": 0}`, reusing `Category.fromJson`.
- [ ] 1.2 Add a `ProductSearchResult` wrapper model (e.g. `lib/models/product_search_result.dart`) carrying `PagedResult<Product> paged` and `List<CategoryCount> categoryCounts`, with `fromJson` parsing both from one response body (`items`, `total`, `page`, `per_page`, `has_next`, `category_counts`).

## 2. Repository

- [ ] 2.1 Add `ProductsRepository.search({String? q, String? category, int page = 1})` in `lib/features/products/products_repository.dart`, calling `GET /products` with snake_case `q`, `category`, `page`, and `per_page` hardcoded to 15, returning `ProductSearchResult`.

## 3. State

- [ ] 3.1 Add a `ProductSearchState` (query text, selected category slug, current page, latest `ProductSearchResult`) and an `AsyncNotifierProvider<ProductSearchNotifier, ProductSearchState>` in the products feature (repository file or a new `product_search_provider.dart` in `lib/features/products/`).
- [ ] 3.2 Implement debounced re-fetch (~400ms) on free-text query changes, resetting to page 1.
- [ ] 3.3 Implement immediate re-fetch (no debounce) on category selection change and on page navigation, preserving the other inputs.
- [ ] 3.4 Ensure `categoryCounts` displayed to the UI reflects only the current `q` and is unaffected by which category is selected (per design.md's decision: counts come from the backend keyed only on `q`).

## 4. Screen

- [ ] 4.1 Add a new search screen (e.g. `lib/features/products/product_search_screen.dart`) with a text search field wired to the notifier's query text.
- [ ] 4.2 Render category filter chips (including an "All" chip) from `categoryCounts`, each showing `name (count)`, with the active chip reflecting `selectedCategory`.
- [ ] 4.3 Render the four screen states (loading, with data, empty, error+retry) following `ProductsListScreen`'s reference pattern.
- [ ] 4.4 Add pagination controls (prev/next, driven by `page`/`hasNext`/`total`/`perPage`), no page-size control.
- [ ] 4.5 Wire navigation entry point to the new search screen (e.g. from the existing products list screen's app bar).

## 5. Tests

- [ ] 5.1 Add `test/category_count_test.dart` (or extend an existing model test file) asserting `CategoryCount.fromJson` parses a snake_case fixture correctly.
- [ ] 5.2 Add tests for `ProductSearchResult.fromJson` asserting it parses `items`, `total`, `page`, `per_page`, `has_next`, and `category_counts` from a snake_case fixture, following `test/product_test.dart`'s pattern.

## 6. Verification

- [ ] 6.1 Run `flutter analyze && flutter test` and confirm both pass.
