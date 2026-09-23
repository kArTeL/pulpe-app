## Context

The app already lists products via `ProductsRepository.list()` and `ProductsListScreen` (infinite-scroll, no filtering). This change adds a separate, filterable, paginated search experience. It is built in parallel with a matching backend change on `pulpe-api` that extends `GET /products` with `q`, `category`, and a `category_counts` response field. The two sides are developed against an agreed contract without waiting on each other's merge.

## Goals / Non-Goals

**Goals:**
- Let the user search products by free text and optionally narrow by category.
- Show, next to each category option, the count of products matching the current free-text query — independent of which category (if any) is currently selected.
- Paginate results at a fixed 15 items per page with explicit page navigation (not infinite scroll, to keep page-based counts stable and simple).
- Reuse this repo's existing conventions: snake_case query params built only in the repository, snake_case→camelCase mapping confined to `lib/models/`, one Riverpod provider per resource, and the four standard screen states.

**Non-Goals:**
- Changing the existing `ProductsListScreen` / `ProductsRepository.list()` behavior.
- Building the backend endpoint itself (tracked in `pulpe-api`).
- A page-size control in the UI — page size is fixed at 15 for this screen.

## Decisions

- **New repository method, not a reuse of `list()`**: `ProductsRepository.search({q, category, page})` is a separate method from `list()` because the response shape differs (it also returns `category_counts`), and mixing an optional wrapper type into `list()`'s simpler `PagedResult<Product>` return would complicate the existing method for no benefit. `per_page` is hardcoded to 15 inside `search()` (not exposed as a parameter) since the UI never varies it.

- **New wrapper model `ProductSearchResult`**: carries `PagedResult<Product>` (reusing the existing generic) plus `List<CategoryCount> categoryCounts`, built from one JSON body in `ProductSearchResult.fromJson`. This keeps `PagedResult<T>` generic and unchanged, and keeps the snake_case mapping for the new sibling field in `lib/models/` alongside the paging fields.

- **`CategoryCount` model**: `{ Category category; int count; }`, with `CategoryCount.fromJson` mapping `{"category": {...}, "count": 0}`. Reuses the existing `Category.fromJson`.

- **Counts don't move when the selected category changes**: this is a request-shape decision, not a UI trick — the repository always requests counts using only `q` (never `category`) semantics, per the backend contract, and the notifier keeps `categoryCounts` from the last fetch stable across category selection. Concretely: the notifier's provider re-fetches from the repository when `q` (debounced) or `page` change; when only `selectedCategory` changes, the fetch still fires (to get the filtered `items` for that category) and the response's `category_counts` list — which was computed by the backend on `q` alone — is used to update the displayed counts. Since the same `q` was sent, values are the same regardless of category, so this satisfies the requirement without needing to suppress a fetch.

- **State provider**: a single `AsyncNotifierProvider<ProductSearchNotifier, ProductSearchState>` (per this repo's one-provider-per-resource rule) holds `queryText`, `selectedCategorySlug`, `page`, and the latest `ProductSearchResult`. Free-text changes go through a debounce (`Timer`, ~400ms) before triggering a re-fetch and resetting `page` to 1. Changing the selected category or page also resets/sets `page` and re-fetches immediately (no debounce needed, these are discrete taps).

- **Pagination UI**: simple prev/next controls plus current page indicator, driven by `page`, `hasNext`, and `total`/`perPage` from `PagedResult`. No infinite scroll here (distinct from `ProductsListScreen`) since page-based navigation is explicitly requested (page 15 items, page navigation).

- **Category chips**: rendered from `categoryCounts` (which includes all categories, even zero-count), each chip showing `"${category.name} (${count})"`; an "All" chip (no filter) is also available and doesn't come from `category_counts` — it represents `category = null`.

## Risks / Trade-offs

- [Risk] Backend not yet merged, so the new params/field don't exist yet in `pulpe-api` → contract mismatch risk. → Mitigation: build strictly against the documented shape in the proposal; if the backend needs to change (e.g. field renamed), only `lib/models/` and the repository method need updating, per this repo's contract isolation.
- [Risk] Debounce could feel laggy or could still fire too often. → Mitigation: 400ms is a reasonable middle ground consistent with typical search UX; easy to tune later, contained to the notifier.
- [Risk] Category selection changing `items` while `categoryCounts` legitimately stays fixed could look like a bug to someone unfamiliar with the requirement. → Mitigation: a short comment in the notifier and a widget test asserting the count is unchanged across category switches.

## Open Questions

- None outstanding; assumptions above (page-based pagination, 400ms debounce, "All" pseudo-chip) are reasonable defaults within the agreed contract and this repo's conventions.
