## ADDED Requirements

### Requirement: Free-text product search
The system SHALL let the user search products by free text via a dedicated search screen, sending the text as the `q` query parameter to `GET /products`.

#### Scenario: User enters search text
- **WHEN** the user types text into the search field
- **THEN** the app fetches matching products from the backend using `q`, after a debounce, and displays the first page of results

#### Scenario: Empty search text
- **WHEN** the search field is empty
- **THEN** the app fetches products without a `q` filter (all products, subject to any selected category)

### Requirement: Category filtering
The system SHALL let the user optionally narrow search results to a single category, sending the category's slug as the `category` query parameter to `GET /products`.

#### Scenario: User selects a category filter
- **WHEN** the user selects a category chip
- **THEN** the app re-fetches results with `category` set to that category's slug, keeping the current search text and resetting to page 1

#### Scenario: User clears the category filter
- **WHEN** the user selects "All" (no category)
- **THEN** the app re-fetches results without a `category` parameter, keeping the current search text

### Requirement: Category result counts independent of selected category
The system SHALL display, next to each category filter option, a count of products matching the current search text. This count SHALL reflect only the free-text query and SHALL NOT change when the user switches which category is selected.

#### Scenario: Switching selected category does not change displayed counts
- **WHEN** the user has search text entered and switches the selected category from one category to another (or to "All")
- **THEN** the count displayed next to each category option remains the same as before the switch

#### Scenario: Changing search text updates displayed counts
- **WHEN** the user changes the free-text search query
- **THEN** the count displayed next to each category option updates to reflect the new search text, once the debounced fetch completes

#### Scenario: Category with zero matches is still shown
- **WHEN** a category has no products matching the current search text
- **THEN** that category is still shown as a filter option, with a count of 0

### Requirement: Paginated results
The system SHALL paginate search results at a fixed 15 items per page (`per_page=15`), with controls to navigate between pages. The UI SHALL NOT expose a control to change the page size.

#### Scenario: Navigating to the next page
- **WHEN** the user has more results available (`has_next` is true) and navigates to the next page
- **THEN** the app fetches page + 1 with the same `q`, `category`, and `per_page=15`, and displays those results

#### Scenario: No further pages available
- **WHEN** the current page is the last page (`has_next` is false)
- **THEN** the next-page control is disabled or hidden

### Requirement: Search screen states
The system SHALL handle all four standard screen states on the search screen: loading, with data, empty, and error with a retry action, consistent with `ProductsListScreen`'s reference pattern.

#### Scenario: Initial load
- **WHEN** the search screen is first opened
- **THEN** a loading indicator is shown while the initial (unfiltered) result set is fetched

#### Scenario: No matching products
- **WHEN** a search (with or without a category filter) returns zero items
- **THEN** an empty-state message is shown instead of a product list

#### Scenario: Fetch fails
- **WHEN** a search request fails (network or API error)
- **THEN** an error state is shown with a retry action that re-issues the same search
