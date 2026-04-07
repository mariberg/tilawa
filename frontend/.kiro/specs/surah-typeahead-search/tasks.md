# Implementation Plan: Surah Typeahead Search

## Overview

Incrementally build the surah typeahead search feature for the Entry Screen. Start with the data model and service layer, then integrate the typeahead widget into the existing UI, wiring everything together with proper error handling and styling.

## Tasks

- [x] 1. Add package dependencies
  - Add `http` and `flutter_typeahead` packages to `pubspec.yaml` under dependencies
  - Add `glados` package to `pubspec.yaml` under dev_dependencies
  - Run `flutter pub get` to install
  - _Requirements: 7.1, 7.2_

- [ ] 2. Implement Surah data model
  - [x] 2.1 Create `lib/models/surah.dart` with the `Surah` class
    - Define fields: `id` (int), `nameSimple` (String), `nameArabic` (String), `translation` (String)
    - Implement `factory Surah.fromJson(Map<String, dynamic> json)` that extracts `id`, `name_simple`, `name_arabic`, and `name_translation.name`
    - Throw `FormatException` with a descriptive message naming the missing field when any required field is missing or null
    - _Requirements: 1.1, 1.2, 1.3_

  - [ ]* 2.2 Write property test for Surah JSON parsing round trip
    - Create `test/models/surah_property_test.dart`
    - **Property 1: Surah JSON parsing round trip**
    - Generate random valid JSON maps, parse via `Surah.fromJson`, assert all fields match original values
    - **Validates: Requirements 1.2, 2.2**

  - [ ]* 2.3 Write property test for missing/null JSON field errors
    - Add to `test/models/surah_property_test.dart`
    - **Property 2: Missing or null JSON fields produce descriptive errors**
    - Generate valid JSON maps then randomly remove or null-ify required fields, assert `fromJson` throws with field name in message
    - **Validates: Requirements 1.3**

  - [ ]* 2.4 Write unit tests for Surah model
    - Create `test/models/surah_test.dart`
    - Test `fromJson` with a real API response snippet
    - Test edge cases: missing nested `name_translation`, null `id`, etc.
    - _Requirements: 1.1, 1.2, 1.3_

- [ ] 3. Implement SurahService with caching
  - [x] 3.1 Create `lib/services/surah_service.dart` with the `SurahService` class
    - Implement `fetchSurahs()` that sends HTTP GET to `https://api.quran.com/api/v4/chapters`
    - Parse the `chapters` array from the response body into `List<Surah>`
    - Cache result in a private `List<Surah>?` field; return cached list on subsequent calls
    - Throw `Exception` with status code message on non-200 responses
    - Propagate network errors (e.g., `SocketException`) without catching
    - Accept an optional `http.Client` parameter for testability
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

  - [ ]* 3.2 Write property test for non-200 status code handling
    - Create `test/services/surah_service_property_test.dart`
    - **Property 3: Non-200 status codes produce exceptions with status code**
    - Generate random non-200 status codes (100–599 excluding 200), mock HTTP response, assert exception message contains the code
    - **Validates: Requirements 2.3**

  - [ ]* 3.3 Write unit tests for SurahService
    - Create `test/services/surah_service_test.dart`
    - Test that GET request targets the correct URL (mock client)
    - Test caching: second call returns cached result without HTTP call
    - Test network error propagation
    - _Requirements: 2.1, 2.4, 2.5_

- [x] 4. Checkpoint - Ensure data and service layer tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Implement filterSurahs function and integrate typeahead into EntryScreen
  - [x] 5.1 Create the `filterSurahs` pure function in `lib/screens/entry_screen.dart`
    - Implement case-insensitive substring match on `nameSimple`
    - Return empty list when query is empty
    - _Requirements: 3.1, 3.2_

  - [ ]* 5.2 Write property test for filter correctness
    - Create `test/screens/filter_surahs_property_test.dart`
    - **Property 4: Filter correctness — case-insensitive substring match**
    - Generate random `Surah` lists and query strings, assert every result contains query (case-insensitive) and every non-result does not; empty query returns empty list
    - **Validates: Requirements 3.1, 3.2**

  - [x] 5.3 Modify `lib/screens/entry_screen.dart` to integrate the typeahead widget
    - Convert `EntryScreen` from `StatelessWidget` to `StatefulWidget`
    - Add `SurahService` instance, `List<Surah>?` state, error state, and loading state fields
    - Call `_surahService.fetchSurahs()` in `initState`
    - Replace the existing `TextField` with `TypeAheadField<Surah>`
    - Wire `suggestionsCallback` to use `filterSurahs` on the cached list
    - Implement `itemBuilder` to display `nameSimple` and `nameArabic` for each suggestion
    - Implement `onSelected` to set the text controller value to the selected surah's `nameSimple`
    - Implement `emptyBuilder` to show "No surahs found" message
    - Show loading indicator in suggestions dropdown while data is loading
    - Show inline error message below the typeahead field when fetch fails
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 4.1, 4.2, 6.1, 6.2_

  - [x] 5.4 Apply visual styling to match existing design
    - Set font size 15, text color `AppColors.textPrimary`, hint text "e.g. 50–54 or Surah Al-Baqarah", underline border
    - Style suggestion items: `AppColors.textPrimary` for `nameSimple`, `AppColors.textSecondary` for `nameArabic`
    - Set suggestion list background to `AppColors.surface`
    - _Requirements: 5.1, 5.2, 5.3_

  - [ ]* 5.5 Write property test for selection populating text field
    - Add to `test/screens/entry_screen_property_test.dart`
    - **Property 5: Selection populates text field with nameSimple**
    - Generate random `Surah` instances, simulate `onSelected` callback, assert text controller value equals `nameSimple`
    - **Validates: Requirements 4.1**

  - [ ]* 5.6 Write unit/widget tests for EntryScreen integration
    - Create `test/screens/entry_screen_test.dart`
    - Widget test: "No surahs found" shown when filter returns empty
    - Widget test: dropdown closes on selection
    - Widget test: error message shown when service fails
    - Widget test: loading indicator shown during fetch
    - _Requirements: 3.3, 4.2, 6.1, 6.2_

- [x] 6. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Property tests use the `glados` package for Dart property-based testing
- The `filterSurahs` function is extracted as a pure function for easy testability
- `SurahService` accepts an optional `http.Client` for mocking in tests
