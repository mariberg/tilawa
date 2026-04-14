# Implementation Plan: Session Feeling API

## Overview

Add `submitFeeling` to `SessionService`, then wire `sessionId` and `sessionService` through the navigation chain from `RecitationScreen` to `FeedbackScreen`, map UI selections to feeling values, and call the API on tap. The existing animation/navigation flow is preserved regardless of API success or failure.

## Tasks

- [x] 1. Add `submitFeeling` method to SessionService
  - [x] 1.1 Implement `submitFeeling` in `lib/services/session_service.dart`
    - Add `Future<void> submitFeeling({required String sessionId, required String feeling, http.Client? client})` method
    - Validate `feeling` is one of `smooth`, `struggled`, `revisit`; throw `ArgumentError` otherwise
    - Read `BASE_URL` and `API_KEY` from `dotenv.env`; throw if missing or empty (same pattern as `prepare` and `submitResults`)
    - Send `PATCH {BASE_URL}/sessions/{sessionId}/feeling` with JSON body `{"feeling": "<value>"}`
    - Set `Content-Type`, `Authorization` (from `_authService.getAuthHeader()`), and `x-api-key` headers
    - Throw `Exception` with status code on non-200 responses
    - Accept optional `http.Client` for testability
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

  - [ ]* 1.2 Write property test for PATCH request construction
    - Create `test/services/session_service_feeling_property_test.dart`
    - **Property 1: PATCH request construction correctness**
    - Generate random non-empty session ID strings and pick a random valid feeling value. Call `submitFeeling` with a mock HTTP client, capture the request, and assert URL path, JSON body, and all three headers are correct.
    - **Validates: Requirements 2.2, 2.3**

  - [ ]* 1.3 Write property test for invalid feeling value rejection
    - Add to `test/services/session_service_feeling_property_test.dart`
    - **Property 2: Invalid feeling values are rejected**
    - Generate random strings excluding `smooth`, `struggled`, `revisit`. Call `submitFeeling` and assert it throws `ArgumentError` without making any HTTP request.
    - **Validates: Requirements 2.4**

  - [ ]* 1.4 Write property test for non-200 status code handling
    - Add to `test/services/session_service_feeling_property_test.dart`
    - **Property 3: Non-200 status codes produce exceptions with status code**
    - Generate random integers in 100–599 excluding 200. Mock HTTP response with that status code. Call `submitFeeling`, assert exception message contains the code.
    - **Validates: Requirements 2.5**

- [x] 2. Checkpoint - Verify service layer
  - Ensure all tests pass, ask the user if questions arise.

- [x] 3. Wire sessionId and sessionService through navigation to FeedbackScreen
  - [x] 3.1 Pass `sessionId` and `sessionService` from `RecitationScreen` to `FeedbackScreen`
    - In `lib/screens/recitation_screen.dart`, extract `_sessionId` from route arguments in `didChangeDependencies` (it needs to be passed from `PrepScreen`)
    - In `_onDone`, change `Navigator.pushReplacementNamed(context, '/feedback')` to pass arguments map with `sessionId` and `sessionService`
    - _Requirements: 1.1, 5.1_

  - [x] 3.2 Pass `sessionId` from `PrepScreen` to `RecitationScreen`
    - In `lib/screens/prep_screen.dart`, add `_sessionId` to the arguments map in `_completeSession` when navigating to `/recitation`
    - _Requirements: 1.1_

  - [x] 3.3 Update `FeedbackScreen` to accept and extract `sessionId` and `sessionService`
    - In `lib/screens/feedback_screen.dart`, add `String? _sessionId` and `SessionService? _sessionService` fields
    - Override `didChangeDependencies` to extract both from `ModalRoute.of(context)?.settings.arguments`
    - If either is missing/null, the screen behaves as before (no API call)
    - _Requirements: 1.2, 1.3, 5.2, 5.3_

- [x] 4. Map UI selection to feeling value and call API
  - [x] 4.1 Add feeling value mapping and call `submitFeeling` on selection
    - In `lib/screens/feedback_screen.dart`, add a static `feelingMap`: `{0: 'smooth', 1: 'struggled', 2: 'revisit'}`
    - In `_submit`, if both `_sessionId` and `_sessionService` are non-null, call `_sessionService!.submitFeeling(sessionId: _sessionId!, feeling: feelingMap[_selected]!)` inside a try/catch
    - On failure, `debugPrint` the error and continue with existing animation/navigation
    - The animation and home navigation must always proceed regardless of API result
    - _Requirements: 3.1, 3.2, 3.3, 4.1, 4.2, 4.3_

  - [ ]* 4.2 Write unit tests for FeedbackScreen feeling submission
    - Create `test/screens/feedback_screen_test.dart`
    - Test that tapping each option maps to the correct feeling value (`smooth`, `struggled`, `revisit`)
    - Test that `submitFeeling` is called with correct sessionId and feeling when both are provided
    - Test that no API call is made when sessionId is null
    - Test that no API call is made when sessionService is null
    - Test that animation/navigation proceeds when `submitFeeling` throws
    - _Requirements: 1.3, 3.1, 3.2, 3.3, 4.1, 4.2, 4.3, 5.3_

- [x] 5. Final checkpoint
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Property tests use the `glados` package (already in dev_dependencies)
- `SessionService` already accepts optional `http.Client` for mocking; `submitFeeling` follows the same pattern
- The `sessionId` is available in `PrepScreen` from the `SessionResponse` but is not currently passed to `RecitationScreen` — task 3.2 fixes this
- `RecitationScreen` receives `SessionService` via `arguments['authService']` (existing naming); the same instance is forwarded to `FeedbackScreen`
