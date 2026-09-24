## Context

`pulpe-app` already lists products via `ProductsRepository.list()` / `ProductsNotifier` / `ProductsListScreen` (`lib/features/products/`), following the loading/data/empty/error-with-retry convention described in `AGENTS.md`. This change adds a sibling search flow in the same feature folder, backed by a new backend endpoint (`GET /products/search`) being built in parallel in `pulpe-api` against a contract fixed by an earlier design scout. That contract is not up for renegotiation here: `q` (optional), `category` (optional slug), `page` (default 1), fixed `per_page` of 15, and the same `{ items, total, page, per_page, has_next }` envelope as `GET /products`.

## Goals / Non-Goals

**Goals:**
- Let a user search products by free text and/or category, with infinite-scroll pagination at 15/page.
- Reuse `Product`, `Category`, and `PagedResult` unchanged — the search response is the same envelope shape already handled by `PagedResult.fromJson`.
- Match the existing screen-state convention (loading / data / empty / error-with-retry) and the existing repository/notifier pattern used by `ProductsRepository` / `ProductsNotifier`.
- Debounce free-text input using only `dart:async` (`Timer`), no new dependency.

**Non-Goals:**
- Changing the `Product`, `Category`, or `PagedResult` models/shapes.
- Fixing the known v1 accent-sensitivity limitation of the backend matching (e.g. "cafe" not matching "Café") — this is accepted server-side behavior for v1, not something to work around client-side.
- Adding a `per_page` control — the page size is fixed server-side at 15 and the client does not send `per_page` for this endpoint.
- Any change to the existing `GET /products` listing screen or its provider.

## Decisions

- **New repository method, not a parameter on `list()`.** `ProductsRepository.search({ q, category, page })` is added alongside `list()`, mirroring how `detail()` and `categories()` already sit next to `list()` in the same class. The query only ever sends `q`/`category`/`page` — no `per_page`, per the fixed backend contract. Alternative considered: overload `list()` with optional search params — rejected because `list()`'s `perPage` parameter has no meaning for this endpoint and it would blur two distinct API calls into one method signature.
- **Separate notifier and screen (`ProductSearchNotifier` / `ProductSearchScreen`), not a mode flag on `ProductsNotifier`.** The existing `ProductsState`/`ProductsNotifier` accumulate pages for the plain listing; search has its own trigger (text change and category change both restart pagination from page 1) and its own empty-state copy ("no results for search" vs. "no products in the catalog"). Mirroring the existing `ProductsState`/`ProductsNotifier` shape as a parallel `ProductSearchState`/`ProductSearchNotifier` in a new `product_search_repository.dart`-adjacent file keeps both simple and keeps `ProductsNotifier` untouched. Alternative considered: adding `query`/`category` fields to `ProductsState` and branching inside `ProductsNotifier` — rejected as it complicates the already-working plain listing for a fairly different interaction model.
- **Debounce with `Timer`, not a new package.** `AGENTS.md` bans new external dependencies; a 300ms-ish `Timer` that resets on every keystroke and fires the search on expiry is standard library and enough for this use case.
- **Category filter value is the slug**, sourced live from `ref.watch`/`ref.read` of a `categoriesProvider` wrapping `ProductsRepository.categories()` (already implemented, currently only used internally) — never a hardcoded list, per the contract note that unrecognized categories are just empty results, not errors, so the client doesn't need to validate the slug itself either.
- **Search state keyed by (query, category)**, not by page alone: any text or category change resets `page` to 1 and clears accumulated items before requesting page 1, exactly like `reload()` does for `ProductsNotifier` today.

## Risks / Trade-offs

- [Debounce timer could fire after the widget/notifier is disposed] → guard with the notifier's own `ref` lifecycle; Riverpod `AsyncNotifier` cancels safely since state writes after dispose are ignored/no-op'd, and the `Timer` is cancelled in the notifier's dispose hook.
- [Rapid category + text changes could race two in-flight requests] → each new search request supersedes the previous one by regenerating the state from a fresh "search token"/generation counter, so a late response for a stale query cannot clobber a newer one — same shape of guard as `loadingMore` already prevents duplicate `loadMore()` calls in `ProductsNotifier`.
- [Accent-insensitive user expectation vs. accent-sensitive backend] → out of scope for this change (see Non-Goals); the empty-state copy on this screen should read generically ("No products match your search.") rather than imply a bug when accents are the cause.

## Open Questions

None — the cross-repo contract (endpoint, params, response shape, fixed page size, empty-result behavior) was pinned by the prior design scout and treated as fixed input to this design.
