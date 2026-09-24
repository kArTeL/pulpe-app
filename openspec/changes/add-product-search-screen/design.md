## Context

`ProductsListScreen` (`lib/features/products/products_list_screen.dart`) and `ProductsRepository` (`lib/features/products/products_repository.dart`) already establish the conventions this screen must follow: query params built in snake_case inside the repository, `fromJson` doing the snake_case→camelCase mapping in `lib/models/`, one `AsyncNotifier` per resource, and infinite-scroll via a `ScrollController` listener. `PagedResult<T>` (`lib/models/paged_result.dart`) is the generic wrapper used by the plain product listing.

The backend contract (`GET /products/search`) is fixed and shared with a parallel `pulpe-api` task; this screen is built directly against it without waiting for the live endpoint.

## Goals / Non-Goals

**Goals:**
- Let the user search products by free text and/or category, paginated at 15/page.
- Surface per-category match counts next to filter options so the user can see result distribution before picking a filter.
- Match existing screen conventions exactly (four states, infinite scroll, Riverpod `AsyncNotifier`).

**Non-Goals:**
- No changes to the plain `GET /products` listing or `PagedResult`.
- No client-side caching/persistence of search history.
- No debounce-cancellation edge-case handling beyond dropping stale results by request identity (no need for cancellable HTTP requests).

## Decisions

- **`ProductSearchResult` as a sibling type, not a `PagedResult` extension.** `PagedResult<T>` is deliberately generic and shared by any future paginated listing. Adding `categoryCounts` to it would leak a search-only concept into every consumer. A small dedicated class (`items`, `total`, `page`, `perPage`, `hasNext`, `categoryCounts`) keeps `PagedResult` untouched.
- **`CategoryCount` as its own model** (`category: Category`, `count: int`) reusing the existing `Category` model, mapped from `{ "category": {...}, "count": 0 }` entries.
- **Repository method signature**: `search({ String? q, String? category, int page = 1, int perPage = 15 })` on `ProductsRepository`, building `{ 'q': q, 'category': category, 'page': page, 'per_page': perPage }` and omitting `q`/`category` when null/empty — `ApiClient._normalizeQuery` already drops null values, so passing `null` through is sufficient.
- **State keying**: the `AsyncNotifier`'s state holds the current `q`/`category` alongside accumulated `items`/`page`/`hasNext`/`loadingMore` (mirroring `ProductsState`). A `search(q, category)` method on the notifier resets to page 1 and replaces `items` whenever either input changes; `loadMore()` behaves like `ProductsNotifier.loadMore()` but reuses the current `q`/`category`.
- **Debounce**: implemented in the screen's `State` via a `Timer` that is cancelled/reset on each text change (300ms), calling the notifier's `search()` after the delay. This avoids adding a debounce dependency — no new package needed.
- **Category filter UI**: a horizontal row of `ChoiceChip`s built from `ProductsRepository.categories()` (fetched once via a `FutureProvider`), each labeled `"name (count)"` when `category_counts` has an entry for that category's slug, or the bare name otherwise. Selecting a chip toggles the `category` filter (tap again to clear).
- **Pagination UX**: infinite-scroll via `ScrollController`, mirroring `ProductsListScreen`'s `_onScroll` threshold, for UX consistency.

## Risks / Trade-offs

- [Category counts reflect only the text search, not the selected category] → this is the specified contract (`category_counts` ignores the current category filter so all options stay visible); documented inline in the repository/model so future readers aren't surprised.
- [Debounced `Timer`-based search races with a fast typer] → each debounce firing calls `search()` with the latest text; the notifier's `search()` always reflects the most recent call since state assignment happens synchronously after each awaited response completes, and any older in-flight response is simply overwritten by a newer one's `AsyncValue.data`. Acceptable for this scope — matches the risk profile of `ProductsNotifier.loadMore()`, which has similar reasoning.
- [Backend endpoint not live yet] → building directly against the fixed, shared contract; no runtime dependency for tests, which mock `ApiClient` at the HTTP layer as `product_test.dart` conventions imply for repository tests.

## Open Questions

None — contract, conventions, and UI approach are all settled by the proposal and existing codebase patterns.
