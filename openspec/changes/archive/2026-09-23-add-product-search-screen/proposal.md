## Why

Shoppers currently have to scroll the full product listing to find something specific. There is no way to search by name or narrow results to a category, so finding a single product in a large catalog is slow. This change adds a dedicated search screen so users can type free text and optionally filter by category.

## What Changes

- Add a new product search screen with a free-text search field, category filter chips, and pagination (15 items per page, fixed page size).
- Category filter chips show a live count of matching products for the current search text; the count for each category stays fixed to the text query and does not change when the user switches which category is selected.
- Add a `ProductsRepository.search(...)` method that calls `GET /products` with the new `q` and `category` query params (built in the repository layer, snake_case) alongside `page` and `per_page=15`.
- Add a `CategoryCount` model and a search-result wrapper type that carries both the paginated product results and the list of category counts, with `fromJson` snake_case → camelCase mapping confined to `lib/models/`.
- Add Riverpod provider(s) for search state (query text, selected category, current page) that re-fetch as those inputs change, with debounced free-text input.

## Capabilities

### New Capabilities
- `product-search`: free-text and category-filtered product search, with per-category result counts and pagination, presented in a dedicated screen.

### Modified Capabilities
(none — the existing product listing capability is unchanged; this adds a new, separate capability)

## Impact

- New files: `lib/models/category_count.dart`, a search result wrapper model, a new search screen under `lib/features/products/`, and Riverpod provider(s) for search state.
- Modified files: `lib/features/products/products_repository.dart` (new `search` method).
- Depends on the `pulpe-api` backend adding `q`/`category` query params and a `category_counts` field to `GET /products`, developed in parallel against the agreed contract.
- New tests in `test/` covering `fromJson` parsing of the new model(s) from snake_case fixtures, following `test/product_test.dart`'s pattern.
