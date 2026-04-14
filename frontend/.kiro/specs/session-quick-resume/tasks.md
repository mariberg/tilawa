# Implementation Plan: Session Quick Resume

## Overview

Bottom-up implementation: update the RecentSession model to support both session types, add pure page-range utilities, create the RevisitBottomSheet widget, integrate tap handlers and display logic into EntryScreen, wire up re-fetch on navigation return, and add property/unit tests throughout.

## Tasks

- [x] 1. Update RecentSession model to support both session types
  - [x] 1.1 Modify `lib/models/recent_session.dart` to make `pages` optional (`String?`), add `surah` field (`int?`), and update `fromJson` to validate at least one is present (throw `FormatException` if both null)
    - Update `toJson` to conditionally include `pages` and `surah`
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

  - [ ]* 1.2 Write property test for RecentSession JSON round-trip
    - **Property 1: RecentSession JSON round-trip**
    - **Validates: Requirements 1.3, 1.4**

  - [ ]* 1.3 Write property test for missing pages and surah throws FormatException
    - **Property 2: Missing pages and surah throws FormatException**
    - **Validates: Requirements 1.5**

- [x] 2. Create page range utilities
  - [x] 2.1 Create `lib/utils/page_utils.dart` with `parsePageRange`, `nextPageRange`, and `formatPageRange` functions
    - `parsePageRange` accepts "Pages {start}–{end}", "{start}-{end}", "Pages {start}", "{start}" formats; returns `({int start, int end, int span})?`
    - `nextPageRange` computes next contiguous range string from start, end, span
    - `formatPageRange` formats start/end back to "{start}-{end}" or "{start}"
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 4.1, 4.2, 4.3_

  - [ ]* 2.2 Write property test for page range parsing round-trip
    - **Property 3: Page range parsing round-trip**
    - **Validates: Requirements 3.1, 3.2, 3.5**

  - [ ]* 2.3 Write property test for invalid pages strings return null
    - **Property 4: Invalid pages strings return null**
    - **Validates: Requirements 3.4**

  - [ ]* 2.4 Write property test for next page range arithmetic
    - **Property 5: Next page range arithmetic**
    - **Validates: Requirements 4.1**

  - [ ]* 2.5 Write unit tests for page_utils edge cases
    - Single page parsing: `parsePageRange("Pages 50")` → `(start: 50, end: 50, span: 1)`
    - Next range for single page: `nextPageRange(50, 50, 1)` → `"51"`
    - Next range example: `nextPageRange(50, 54, 5)` → `"55-59"`
    - _Requirements: 3.3, 4.2, 4.3_

- [x] 3. Checkpoint — Ensure model and utility tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 4. Create RevisitBottomSheet widget
  - [x] 4.1 Create `lib/widgets/revisit_bottom_sheet.dart` with `RevisitBottomSheet` stateless widget
    - Accept `revisitLabel` and `moveOnLabel` strings
    - Return `'revisit'` or `'moveOn'` via `Navigator.pop`, or `null` on dismiss
    - Style with `AppColors.surface`, rounded top corners, drag handle, two `InkWell` option rows
    - _Requirements: 8.1, 8.2, 9.1, 9.2_

- [x] 5. Integrate tap handling and display logic into EntryScreen
  - [x] 5.1 Add `_surahName` and `_nextSurahName` helper methods to `_EntryScreenState`
    - `_surahName(int id)` looks up `nameSimple` from `_surahs`, returns `null` if not found
    - `_nextSurahName(int currentId)` computes next ID (wrap 114→1) and looks up name
    - _Requirements: 5.1, 5.2, 5.3_

  - [ ]* 5.2 Write property test for next surah wrapping
    - **Property 6: Next surah wrapping**
    - **Validates: Requirements 5.1, 5.2**

  - [x] 5.3 Add `_sessionTitle` method to compute display title per session type
    - Page sessions: return `session.pages!`
    - Surah sessions: return `_surahName(session.surah!)` or fallback `"Surah {id}"`
    - _Requirements: 2.1, 2.2, 2.3_

  - [ ]* 5.4 Write property test for session title computation
    - **Property 7: Session title computation**
    - **Validates: Requirements 2.1, 2.2**

  - [x] 5.5 Add `_onRecentSessionTap`, `_handlePageSessionTap`, and `_handleSurahSessionTap` methods
    - Route to page or surah handler based on which field is non-null
    - Non-revisit page sessions: parse pages, pre-fill `_textController` with `nextPageRange`
    - Non-revisit surah sessions: pre-fill with `_nextSurahName`
    - Revisit sessions: show `RevisitBottomSheet`, pre-fill based on user choice
    - Guard against unparseable pages (no action) and missing surah (no action / no bottom sheet)
    - _Requirements: 6.1, 6.2, 6.3, 7.1, 7.2, 7.3, 8.1, 8.3, 8.4, 8.5, 8.6, 9.1, 9.3, 9.4, 9.5, 9.6_

  - [ ]* 5.6 Write property test for non-revisit tap pre-fills next content
    - **Property 8: Non-revisit tap pre-fills next content**
    - **Validates: Requirements 6.1, 7.1**

  - [ ]* 5.7 Write property test for revisit choice pre-fills correct content
    - **Property 9: Revisit choice pre-fills correct content**
    - **Validates: Requirements 8.3, 8.4, 9.3, 9.4**

  - [x] 5.8 Convert `_recentRow` from static method to instance method, wrap in `InkWell`, pass `RecentSession` object, use `_sessionTitle` for title and `_onRecentSessionTap` for `onTap`
    - Update the `_recentSessions` list rendering in `build()` to call the new instance method
    - _Requirements: 11.1, 11.2_

- [x] 6. Checkpoint — Ensure tap handling and display tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 7. Re-fetch recent sessions on navigation return
  - [x] 7.1 In `_prepare()`, change `Navigator.pushNamed` to `await Navigator.pushNamed`, then call `_loadRecentSessions()` when the future resolves (user navigates back)
    - Ensure `mounted` check before calling `_loadRecentSessions`
    - Loading indicator and error handling already exist in `_loadRecentSessions`
    - _Requirements: 10.1, 10.2, 10.3, 10.4_

- [x] 8. Final checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties from the design document
- The `glados` package (already in dev_dependencies) is used for property-based tests
