## ADDED Requirements

### Requirement: Free-text and category product search
The system SHALL let the user search products by free text and, optionally, by category, via `GET /products/search`, paginated at 15 items per page.

#### Scenario: Text-only search
- **WHEN** the user types a search query and no category is selected
- **THEN** the app calls `GET /products/search` with `q` set to the typed text, `page=1`, `per_page=15`, and no `category` param, and shows the returned items

#### Scenario: Text search debounced
- **WHEN** the user types multiple characters in quick succession
- **THEN** the app waits until typing pauses (300-400ms) before issuing a search request, rather than firing one request per keystroke

#### Scenario: Category filter applied
- **WHEN** the user selects a category filter (with or without a text query)
- **THEN** the app calls `GET /products/search` with `category` set to that category's slug, and resets results to page 1

#### Scenario: Changing query or category resets pagination
- **WHEN** the user changes the search text or the selected category after having loaded additional pages
- **THEN** the app discards previously accumulated results and re-fetches from page 1 with the new `q`/`category`

#### Scenario: Loading more results
- **WHEN** the user scrolls near the end of the current results and `has_next` is true
- **THEN** the app requests the next page with the same `q`/`category` and appends the returned items to the existing list

### Requirement: Category match counts
The system SHALL display, for each category, the number of matches under the current text search (ignoring the currently selected category filter), so all filter options remain visible with their counts even when one is selected.

#### Scenario: Counts shown alongside filter options
- **WHEN** a search response includes `category_counts`
- **THEN** the app shows each listed category's count next to its filter option

#### Scenario: Counts persist across category selection
- **WHEN** the user selects a category filter
- **THEN** the displayed counts for all categories remain based on the text search alone, not narrowed to the selected category

### Requirement: Screen states
The system SHALL present the search screen in one of four states at any time: loading, with data, empty, or error with a retry action.

#### Scenario: Initial loading
- **WHEN** a search request is in flight and no prior results are shown
- **THEN** the screen shows a loading indicator

#### Scenario: No matches
- **WHEN** a search request succeeds but returns zero items
- **THEN** the screen shows an empty-state message indicating no products match the search

#### Scenario: Request failure
- **WHEN** a search request fails (network or API error)
- **THEN** the screen shows an error message with a retry button that re-issues the same search
