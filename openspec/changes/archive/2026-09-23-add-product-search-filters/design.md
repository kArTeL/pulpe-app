## Context

`ProductsListScreen` currently drives a single `AsyncNotifierProvider<ProductsNotifier, ProductsState>` that paginates through `GET /products` (`page`/`per_page`) via `ProductsRepository.list()`. The backend (`pulpe-api`, developed in parallel) is adding two optional query params to that same endpoint: `search` (partial match on name/description) and `category` (slug filter). The response wrapper shape is unchanged.

## Goals / Non-Goals

**Goals:**
- Let the user type free text to search products and/or pick a category to filter.
- Keep the existing four screen states (loading, data, empty, error-with-retry) — no new states.
- Compose cleanly with existing pagination: changing a filter restarts pagination at page 1.

**Non-Goals:**
- Price-range or in-stock filters.
- Sorting.
- Any change to the pagination or error contract shape.
- Multi-category selection (single category or "all" only, per the proposal).

## Decisions

- **Filter state lives in `ProductsState`/`ProductsNotifier`**, not in local widget `setState`, per AGENTS.md ("no setState for data coming from the API"). Add `search` and `category` fields to `ProductsState`; add `ProductsNotifier.setSearch(String)` and `ProductsNotifier.setCategory(String?)` methods that update the filter and reload from page 1.
- **Debounce lives in the screen widget**, not the notifier: the text field's `onChanged` starts/resets a `Timer` (dart:async, no new dependency) and only calls `ref.read(productsProvider.notifier).setSearch(...)` after ~400ms of inactivity. This keeps the notifier simple (it always reloads immediately on a param change) and matches Flutter convention for input-driven debouncing.
- **Category source**: reuse `ProductsRepository.categories()` (already exists, hits `GET /categories`) via a small `categoriesProvider` (`FutureProvider<List<Category>>`). Rendered as a horizontal `Wrap`/`ListView` of `FilterChip`s, with an "All" chip representing `category == null`.
- **Query param wiring**: `ProductsRepository.list()` gains `String? search` and `String? category` params, added to the query map only when non-null and non-empty (trimmed for search), keeping keys `search`/`category` in snake_case — trivially snake_case already since both are single words.
- **Reset-on-change**: both `setSearch` and `setCategory` reset `page` to 0 and replace (not append) `products`, reusing the same `_loadFirstPage`-style path already used by `reload()`, just parameterized with the current filter state.

## Risks / Trade-offs

- [Rapid typing could fire multiple in-flight requests before debounce settles] → Debounce timer cancels the previous pending call before scheduling a new one; the notifier's reload path already replaces state atomically so a late response only matters if it's the latest one — mitigated by checking notifier's current filter still matches after await, otherwise it's dropped implicitly by the next reload overwriting state.
- [Empty search box vs `null`] → repository only sends `search` when the trimmed string is non-empty, so clearing the box naturally falls back to unfiltered results.

