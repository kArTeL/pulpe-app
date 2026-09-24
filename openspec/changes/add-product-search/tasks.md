## 1. Repository

- [x] 1.1 Add `ProductSearchQuery` (or plain params) and a `search({ q, category, page })` method to `ProductsRepository` in `lib/features/products/products_repository.dart`, calling `GET /products/search` with only `q`, `category`, `page` (never `per_page`), returning `PagedResult<Product>` via the existing `PagedResult.fromJson` + `Product.fromJson`.
- [x] 1.2 Ensure a `categoriesProvider` (or equivalent) exposes `ProductsRepository.categories()` for reuse by the search screen.

## 2. State / Notifier

- [x] 2.1 Add `ProductSearchState` (query text, selected category slug, accumulated products, current page, hasNext, loadingMore) in `products_repository.dart`, alongside `ProductsState`/`ProductsNotifier` (one provider per resource, in its feature's repository file, per `AGENTS.md`).
- [x] 2.2 Add `ProductSearchNotifier` (`AsyncNotifier`) with: `updateQuery(text)` (debounced via `Timer`, resets to page 1), `selectCategory(slug?)` (resets to page 1), `loadMore()` (guarded like `ProductsNotifier.loadMore`), and `retry()` for the error state.
- [x] 2.3 Guard against stale in-flight requests when query/category change rapidly (e.g. a generation/token counter), so a late response cannot overwrite newer state.
- [x] 2.4 Cancel the debounce `Timer` on notifier disposal.

## 3. UI

- [x] 3.1 Add `ProductSearchScreen` under `lib/features/products/` with a search text field and a category filter control populated from `GET /categories`.
- [x] 3.2 Implement the four screen states (loading / data / empty / error-with-retry) following `ProductsListScreen`'s pattern, including infinite scroll via a `ScrollController` near-end listener calling `loadMore()`.
- [x] 3.3 Empty state copy should read as "no results for this search/filter", distinct from the plain catalog's empty-state copy.
- [x] 3.4 Wire a "Search products" entry point from `ProductsListScreen` (or `main.dart`) to `ProductSearchScreen`.

## 4. Tests

- [x] 4.1 Repository test: `ProductsRepository.search` sends `q`/`category`/`page` correctly (and omits absent ones), never sends `per_page`, and parses the response with the existing `PagedResult`/`Product` models.
- [x] 4.2 Notifier/state test: query change and category change each reset to page 1 and discard prior results; `loadMore()` appends and stops at `has_next: false`; a stale response does not overwrite newer state.
- [x] 4.3 Widget/screen test: empty state renders when `items` is empty; error state renders with a working retry control on request failure.

## 5. OpenSpec

- [x] 5.1 `openspec validate --changes add-product-search` passes with no errors.
