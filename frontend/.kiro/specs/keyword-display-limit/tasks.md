# Tasks: Keyword Display Limit

## Task 1: Create KeywordSelectionRecord and SessionResultPayload data models

- [x] 1.1 Create `lib/models/keyword_selection_record.dart` with `arabic`, `category` fields, `toJson()`, and `fromJson()` factory
- [x] 1.2 Create `lib/models/session_result_payload.dart` with `pages`, `surah`, `keywords` fields, `toJson()`, and `fromJson()` factory
- [ ] 1.3 Write unit tests for `KeywordSelectionRecord` JSON serialization
- [ ] 1.4 Write unit tests for `SessionResultPayload` JSON serialization
- [ ] 1.5 Write property test: SessionResultPayload serialization round trip (Property 9)

## Task 2: Implement KeywordDisplayManager

- [x] 2.1 Create `lib/services/keyword_display_manager.dart` with `displayLimit` constant, constructor that splits full list into visible/reserve, and `replaceKnown(index)` method
- [ ] 2.2 Write property test: Initial visible set is first min(displayLimit, length) keywords (Property 1)
- [ ] 2.3 Write property test: replaceKnown with reserve inserts next reserve at same position (Property 2)
- [ ] 2.4 Write property test: replaceKnown without reserve shrinks visible by one (Property 3)
- [ ] 2.5 Write property test: Visible and reserve partition the full list in original order (Property 4)
- [ ] 2.6 Write unit tests for edge cases: 0 keywords, exactly 7 keywords, displayLimit constant equals 7

## Task 3: Implement SelectionTracker

- [x] 3.1 Create `lib/services/selection_tracker.dart` with `record()`, `getRecords()`, `count`, and `reset()` methods
- [ ] 3.2 Write property test: Recording a category stores the correct category (Property 5)
- [ ] 3.3 Write property test: All recorded keywords are retrievable (Property 6)
- [ ] 3.4 Write property test: One record per unique arabic string (Property 7)
- [ ] 3.5 Write property test: Last-write-wins for duplicate recordings (Property 8)
- [ ] 3.6 Write unit tests for edge cases: empty tracker initialization, reset clears records

## Task 4: Add submitResults method to SessionService

- [x] 4.1 Add `submitResults()` method to `lib/services/session_service.dart` that POSTs `SessionResultPayload` to `{BASE_URL}/sessions/complete`
- [ ] 4.2 Write property test: Non-200 status codes throw with status code in message (Property 10)
- [ ] 4.3 Write unit tests: correct URL, auth headers, network error propagation

## Task 5: Refactor PrepScreen to use KeywordDisplayManager and SelectionTracker

- [x] 5.1 Update `lib/screens/prep_screen.dart` to accept `pages`/`surah`/`sessionId` from route arguments and instantiate `KeywordDisplayManager` and `SelectionTracker`
- [x] 5.2 Update "Known" action to call `tracker.record()` and `manager.replaceKnown()`, staying on same card index
- [x] 5.3 Update "Not sure" and "Review" actions to call `tracker.record()` and advance to next card
- [x] 5.4 Update card counter and `DotIndicator` to use `manager.totalVisible`
- [x] 5.5 On last card action, call `sessionService.submitResults()` with tracker records, then navigate to recitation screen

## Task 6: Update EntryScreen to pass session scope through route arguments

- [x] 6.1 Update `lib/screens/entry_screen.dart` to include `pages`, `surah`, and `AuthService` in the route arguments passed to PrepScreen
