# Tasks: Keyword Rating Simplification

## Task 1: Update KeywordSelectionRecord to validate status values
- [x] 1.1 Add `static const validStatuses = {'known', 'not_known'}` to `KeywordSelectionRecord`
- [x] 1.2 Add status validation in `fromJson()` that throws `FormatException` for invalid status values
- [x] 1.3 Update existing tests in `test/models/keyword_selection_record_test.dart` to use `"not_known"` instead of `"not_sure"` and `"review"`
- [x] 1.4 Add unit test: `fromJson` with `"not_sure"` throws `FormatException`
- [x] 1.5 Add unit test: `fromJson` with `"review"` throws `FormatException`
- [x] 1.6 Add property test: KeywordSelectionRecord serialization round trip (Property 4)

## Task 2: Update SelectionTracker to validate and use new status values
- [x] 2.1 Add status validation in `SelectionTracker.record()` that throws `ArgumentError` for values other than `"known"` and `"not_known"`
- [x] 2.2 Add property test: SelectionTracker recording fidelity (Property 1)
- [x] 2.3 Add property test: SelectionTracker rejects invalid statuses (Property 2)
- [x] 2.4 Add unit test: `record()` with `"not_sure"` throws `ArgumentError`
- [x] 2.5 Add unit test: `record()` with `"review"` throws `ArgumentError`

## Task 3: Update PrepScreen UI to two-button rating
- [x] 3.1 Replace `_handleNotSureOrReview(String status)` with `_handleNotKnown()` that records `"not_known"` and advances
- [x] 3.2 Update `_setCardState()` to handle only state values 1 (Known) and 2 (Not known), removing state value 3
- [x] 3.3 Update button row from 3 buttons to 2 buttons: `"✓ Known"` (state 1) and `"✗ Not known"` (state 2)

## Task 4: Update existing tests for SessionResultPayload
- [x] 4.1 Update `test/models/session_result_payload_test.dart` to use `"not_known"` instead of `"not_sure"` and `"review"` in all test fixtures

## Task 5: Add PrepScreen advance-without-replacement property test
- [x] 5.1 Add property test: "Not known" advances index without modifying visible list (Property 3)
