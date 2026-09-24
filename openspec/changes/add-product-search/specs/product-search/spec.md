## ADDED Requirements

### Requirement: Search products by free text
The system SHALL let the user search products by free-text query, sending the entered text as the `q` query parameter to `GET /products/search`, debounced so that a request is only sent after the user pauses typing rather than on every keystroke.

#### Scenario: User types a search term
- **WHEN** the user types text into the search field and pauses
- **THEN** the app sends a debounced `GET /products/search` request with `q` set to the entered text and displays the returned products

#### Scenario: User clears the search field
- **WHEN** the user clears the search field to empty
- **THEN** the app sends a debounced `GET /products/search` request without a `q` parameter, showing results for any active category filter alone

### Requirement: Filter search by category
The system SHALL let the user filter search results by category, with the available categories sourced from `GET /categories` (never a hardcoded list), sending the selected category's `slug` as the `category` query parameter to `GET /products/search`.

#### Scenario: User selects a category filter
- **WHEN** the user selects a category from the list returned by `GET /categories`
- **THEN** the app sends a `GET /products/search` request with `category` set to that category's slug, combined with any active text query

#### Scenario: User clears the category filter
- **WHEN** the user deselects the active category filter
- **THEN** the app sends a `GET /products/search` request without a `category` parameter, showing results for any active text query alone

### Requirement: Paginated results at a fixed page size
The system SHALL display search results paginated at 15 items per page using infinite scroll, requesting subsequent pages via the `page` query parameter and stopping once the response's `has_next` is false. The client SHALL NOT send a `per_page` parameter; the page size is fixed server-side.

#### Scenario: User scrolls near the end of the loaded results
- **WHEN** the user scrolls near the bottom of the currently loaded results and the last response had `has_next: true`
- **THEN** the app requests the next page (`page` incremented by 1, no `per_page` sent) and appends the returned items to the list

#### Scenario: Last page reached
- **WHEN** the most recently loaded page's response has `has_next: false`
- **THEN** the app stops requesting further pages and does not show a "loading more" indicator

### Requirement: Changing search or filter restarts pagination
The system SHALL restart pagination from page 1 and discard previously accumulated results whenever the free-text query or the category filter changes.

#### Scenario: User changes the search text after scrolling through results
- **WHEN** the user has scrolled to load multiple pages and then changes the search text
- **THEN** the app discards the previously loaded items and requests page 1 for the new text (and current category, if any)

#### Scenario: User changes the category filter after scrolling through results
- **WHEN** the user has scrolled to load multiple pages and then changes the category filter
- **THEN** the app discards the previously loaded items and requests page 1 for the new category (and current text, if any)

### Requirement: Loading, data, empty, and error-with-retry states
The system SHALL present the search screen in one of four states, matching the app's existing screen-state convention: loading (initial request in flight), data (results shown), empty (a successful response with no items), and error-with-retry (a failed request, with a control to retry the same query/category/page-1 request).

#### Scenario: Initial search request is in flight
- **WHEN** the debounced search request for a new query or category is sent and no results have loaded yet
- **THEN** the screen shows a loading state

#### Scenario: Search returns no matches
- **WHEN** `GET /products/search` returns a successful response with an empty `items` array (no matches, or the selected category is unrecognized server-side)
- **THEN** the screen shows an empty state, not an error

#### Scenario: Search request fails
- **WHEN** `GET /products/search` fails with a network error or an API error
- **THEN** the screen shows an error state with a retry control that re-issues the same request (current text and category, page 1)

### Requirement: Search reuses existing product and pagination models
The system SHALL parse `GET /products/search` responses using the existing `PagedResult<Product>` and `Product`/`Category` models unchanged, since the response envelope and item shape are identical to `GET /products`.

#### Scenario: Search response is parsed
- **WHEN** the app receives a `GET /products/search` response
- **THEN** the app parses it with `PagedResult<Product>.fromJson` and `Product.fromJson`, the same parsing used for `GET /products`, without any search-specific model or field mapping
