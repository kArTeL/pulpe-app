# product-search-filter Specification

## Purpose
TBD - created by archiving change add-product-search-filters. Update Purpose after archive.
## Requirements
### Requirement: Free-text product search
The products listing screen SHALL provide a debounced search text field that filters the product list by a case-insensitive partial match against product name or description, using the backend's `search` query parameter.

#### Scenario: User types a search term
- **WHEN** the user types text into the search field and stops typing
- **THEN** the app SHALL request page 1 of `GET /products` with `search` set to the trimmed text, and replace the current list with the results

#### Scenario: User clears the search field
- **WHEN** the search field is cleared to empty text
- **THEN** the app SHALL request page 1 of `GET /products` without a `search` parameter

#### Scenario: Search input is debounced
- **WHEN** the user types multiple characters in quick succession
- **THEN** the app SHALL NOT issue a request for every keystroke; only one request SHALL be issued after typing pauses

### Requirement: Category filter
The products listing screen SHALL provide a category filter, sourced from `GET /categories`, that lets the user narrow the list to a single category slug or clear it back to "all", using the backend's `category` query parameter.

#### Scenario: User selects a category
- **WHEN** the user selects a category from the filter
- **THEN** the app SHALL request page 1 of `GET /products` with `category` set to that category's slug, and replace the current list with the results

#### Scenario: User clears the category filter
- **WHEN** the user selects "All" (or otherwise clears the category filter)
- **THEN** the app SHALL request page 1 of `GET /products` without a `category` parameter

### Requirement: Filters compose with pagination
Search and category filters SHALL compose with the existing pagination/infinite-scroll behavior of the products listing screen.

#### Scenario: Changing a filter resets pagination
- **WHEN** the search text or category filter changes
- **THEN** the app SHALL discard any previously accumulated pages and reload starting from page 1

#### Scenario: Scrolling loads more of the filtered result set
- **WHEN** the user scrolls near the end of a filtered list and more pages are available (`has_next: true`)
- **THEN** the app SHALL load the next page using the same active `search`/`category` parameters and append the results

#### Scenario: Filtered result set is empty
- **WHEN** a search and/or category filter produces zero results
- **THEN** the screen SHALL show the existing empty state, not a new or different UI state

#### Scenario: Filtered request fails
- **WHEN** a request for a filtered page fails
- **THEN** the screen SHALL show the existing error state with a retry button, and retrying SHALL reuse the same active `search`/`category` parameters

