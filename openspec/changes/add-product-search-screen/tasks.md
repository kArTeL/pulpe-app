## 1. Models

- [ ] 1.1 Add `lib/models/category_count.dart` with `CategoryCount { category: Category, count: int }` and `fromJson` mapping `{ "category": {...}, "count": 0 }`.
- [ ] 1.2 Add `lib/models/product_search_result.dart` with `ProductSearchResult<T>` (or non-generic if simpler, keyed to `Product`) carrying `items`, `total`, `page`, `perPage`, `hasNext`, `categoryCounts`, and a `fromJson` mapping the response including the `category_counts` list.

## 2. Repository

- [ ] 2.1 Add `ProductsRepository.search({ String? q, String? category, int page = 1, int perPage = 15 })` in `lib/features/products/products_repository.dart`, calling `ApiClient.get('/products/search', query: { 'q': q, 'category': category, 'page': page, 'per_page': perPage })` and returning `ProductSearchResult`.

## 3. State management

- [ ] 3.1 Add `ProductSearchState` (mirrors `ProductsState`, plus `q`, `category`, `categoryCounts`) in `products_repository.dart` or a new `product_search_notifier.dart`.
- [ ] 3.2 Add `ProductSearchNotifier extends AsyncNotifier<ProductSearchState>` with `search(String? q, String? category)` (resets to page 1) and `loadMore()` (reuses current `q`/`category`), following `ProductsNotifier`'s shape.
- [ ] 3.3 Wire the `productSearchProvider` (`AsyncNotifierProvider`).

## 4. Screen

- [ ] 4.1 Create `lib/features/products/product_search_screen.dart` with a debounced (300-400ms) search `TextField` using a `Timer`.
- [ ] 4.2 Add a category filter row (`ChoiceChip`s) populated from `ProductsRepository.categories()`, labeling each with its `category_counts` count when present.
- [ ] 4.3 Implement infinite-scroll pagination via `ScrollController`, matching `ProductsListScreen`'s `_onScroll` pattern.
- [ ] 4.4 Implement all four screen states (loading, data, empty "No products match your search", error + retry), copying `ProductsListScreen`'s `_EmptyState`/`_ErrorState` pattern.
- [ ] 4.5 Add a search action (e.g. `IconButton(Icons.search)`) to `ProductsListScreen`'s `AppBar` that navigates to `ProductSearchScreen`.

## 5. Tests

- [ ] 5.1 Add `test/product_search_test.dart` covering `CategoryCount.fromJson` and `ProductSearchResult.fromJson` (including `category_counts` parsing), following `test/product_test.dart`'s convention.
- [ ] 5.2 Add repository tests verifying `ProductsRepository.search()` builds the correct snake_case query params (`q`, `category`, `page`, `per_page`) and omits `q`/`category` when null/empty.

## 6. Verification

- [ ] 6.1 Run `flutter analyze && flutter test` and fix any issues.
