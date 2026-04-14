# Implementation Plan: Recent Sessions Display

## Overview

Replace hardcoded recent session rows on the Entry Screen with live data from `GET /sessions/recent`. Implementation proceeds bottom-up: data model → utility function → service method → UI integration → cleanup.

## Tasks

- [x] 1. Create RecentSession model
  - [x] 1.1 Create `lib/models/recent_session.dart` with `RecentSession` class
    - Define fields: `sessionId` (String), `pages` (String), `feeling` (String), `createdAt` (DateTime)
    - Implement `fromJson` factory that validates all required fields are present and non-null, throws `FormatException` for missing fields
    - Implement `toJson` method that serializes back to the same JSON shape
    - Parse `createdAt` from ISO 8601 string via `DateTime.parse`
    - _Requirements: 2.1, 2.2, 2.3_

  - [ ]* 1.2 Write property test for RecentSession JSON round-trip
    - **Property 2: RecentSession JSON round-trip**
    - **Validates: Requirements 2.1, 2.3**
    - Generate random `RecentSession` instances with non-empty strings for sessionId/pages, feeling from `{smooth, struggled, revisit}`, and random DateTime values
    - Serialize via `toJson`, deserialize via `fromJson`, assert all fields match

- [x] 2. Create formatRelativeDate utility
  - [x] 2.1 Create `lib/utils/date_utils.dart` with `formatRelativeDate` function
    - Signature: `String formatRelativeDate(DateTime date, {DateTime? now})`
    - Compute calendar day difference between `date` and `now` (defaults to `DateTime.now()`)
    - Return: "Today" (0 days), "Yesterday" (1 day), "{n} days ago" (2–6), "1 week ago" (7–13), "{n} weeks ago" (14+)
    - _Requirements: 3.2_

  - [ ]* 2.2 Write property test for formatRelativeDate
    - **Property 5: Relative date formatting correctness**
    - **Validates: Requirements 3.2**
    - Generate random DateTime pairs where date <= now
    - Assert returned string matches expected category based on day difference
    - Assert returned string is always non-empty

- [x] 3. Checkpoint - Ensure model and utility tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 4. Add fetchRecentSessions to SessionService
  - [x] 4.1 Add `fetchRecentSessions` method to `lib/services/session_service.dart`
    - Add import for `RecentSession` model
    - Follow existing `prepare()` pattern: read `BASE_URL` and `API_KEY` from `dotenv.env`, throw if missing/empty
    - Send `GET {BASE_URL}/sessions/recent` with `Authorization` from `_authService.getAuthHeader()` and `x-api-key` headers
    - On 200: decode JSON body as List, map each element through `RecentSession.fromJson`, return the list
    - On non-200: throw `Exception('Fetch recent sessions failed: status ${response.statusCode}')`
    - Accept optional `http.Client` parameter for testability
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 2.1, 2.4, 2.5_

  - [ ]* 4.2 Write property test for GET request construction
    - **Property 1: GET request construction correctness**
    - **Validates: Requirements 1.2, 1.3**
    - Generate random BASE_URL strings, user IDs, and API keys
    - Call `fetchRecentSessions` with a mock HTTP client, capture the request
    - Assert URL equals `{BASE_URL}/sessions/recent`, Authorization header matches auth service output, x-api-key header matches configured key

  - [ ]* 4.3 Write property test for non-200 status codes
    - **Property 3: Non-200 status codes produce exceptions with status code**
    - **Validates: Requirements 2.4**
    - Generate random HTTP status codes in 100–599 excluding 200
    - Mock response with that status code, call `fetchRecentSessions`
    - Assert exception message contains the numeric status code

  - [ ]* 4.4 Write property test for invalid JSON responses
    - **Property 4: Invalid JSON throws parsing error**
    - **Validates: Requirements 2.5**
    - Generate random strings that are not valid JSON
    - Mock a 200 response with that body, call `fetchRecentSessions`
    - Assert `FormatException` is thrown

  - [ ]* 4.5 Write unit tests for fetchRecentSessions edge cases
    - Test BASE_URL missing throws descriptive error (Req 1.4)
    - Test API_KEY missing throws descriptive error (Req 1.5)

- [x] 5. Checkpoint - Ensure service layer tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 6. Update EntryScreen to use live recent sessions data
  - [x] 6.1 Add state variables and fetch logic to EntryScreen
    - Import `RecentSession` model and `formatRelativeDate` utility
    - Add state variables: `List<RecentSession>? _recentSessions`, `bool _isLoadingRecent = true`, `String? _recentError`
    - Add `_loadRecentSessions()` method that calls `_sessionService!.fetchRecentSessions()`, updates state on success/failure
    - Call `_loadRecentSessions()` in `didChangeDependencies` after `_sessionService` is created
    - _Requirements: 3.1_

  - [x] 6.2 Replace hardcoded rows with dynamic recent sessions section
    - Remove the two hardcoded `_recentRow('Pages 50–54', 'Yesterday')` and `_recentRow('Pages 12–15', '3 days ago')` calls and the static divider between them
    - Render based on state: loading → small centered `CircularProgressIndicator`, error → short error text in `AppColors.textMuted`, empty list → "No recent sessions" text in `AppColors.textMuted`, data → map `_recentSessions` to `_recentRow` calls with `formatRelativeDate` for date
    - _Requirements: 3.2, 3.3, 3.4, 3.5, 3.6, 5.1, 5.2_

  - [x] 6.3 Add revisit indicator to session rows
    - Update `_recentRow` to accept an optional `showRevisit` parameter
    - When `showRevisit` is true, display a small "Revisit" label styled with `AppColors.primary` text on `AppColors.primaryLight` background
    - Pass `showRevisit: session.feeling == 'revisit'` when building rows from data
    - _Requirements: 4.1, 4.2, 4.3_

  - [ ]* 6.4 Write property test for revisit indicator logic
    - **Property 6: Revisit indicator shown if and only if feeling is 'revisit'**
    - **Validates: Requirements 4.1, 4.2**
    - Generate random RecentSession instances with feeling from `{smooth, struggled, revisit}`
    - Assert revisit indicator visibility equals `(feeling == 'revisit')`

- [x] 7. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Property tests use the `glados` package already in dev_dependencies
- Mock HTTP client used for all service-level tests
- The implementation follows existing patterns in SessionService (`prepare()`, `submitResults()`, `submitFeeling()`)
