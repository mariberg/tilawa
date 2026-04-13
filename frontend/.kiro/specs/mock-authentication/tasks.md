# Implementation Plan: Mock Authentication

## Overview

Add mock authentication across the Flutter frontend and AWS Lambda backend. Start with the frontend AuthService, then the UI selector widget, then update SessionService to use dynamic auth, then implement the backend token extraction utility.

## Tasks

- [x] 1. Implement AuthService
  - [x] 1.1 Create `lib/services/auth_service.dart` with the `AuthService` class
    - Define `static const List<String> validUsers` containing `demo-user-1`, `demo-user-2`, `demo-user-3`
    - Define `static const String defaultUser = 'demo-user-1'`
    - Store `_currentUser` as a private `String` field initialized to `defaultUser`
    - Implement `String get currentUser` getter
    - Implement `void setUser(String userId)` that validates against `validUsers` and throws `ArgumentError` for invalid IDs
    - Implement `String getAuthHeader()` returning `'Bearer $_currentUser'`
    - _Requirements: 1.3, 2.1, 2.2, 2.3_

  - [ ]* 1.2 Write property test for AuthService set/get round trip
    - Create `test/services/auth_service_property_test.dart`
    - **Property 1: AuthService set/get round trip**
    - For each valid user ID, call `setUser`, then assert `currentUser` returns the same ID
    - **Validates: Requirements 1.3, 2.1**

  - [ ]* 1.3 Write property test for auth header format
    - Add to `test/services/auth_service_property_test.dart`
    - **Property 2: Auth header format**
    - For each valid user ID, set it, call `getAuthHeader()`, assert result equals `"Bearer " + userId`
    - **Validates: Requirements 2.2**

  - [ ]* 1.4 Write unit tests for AuthService
    - Create `test/services/auth_service_test.dart`
    - Test default user is `demo-user-1` on fresh instance
    - Test `setUser` with invalid ID throws `ArgumentError`
    - _Requirements: 2.3, 1.3_

- [x] 2. Implement UserSelectorWidget
  - [x] 2.1 Create `lib/widgets/user_selector.dart` with the `UserSelectorWidget`
    - Accept `AuthService authService` and optional `ValueChanged<String>? onChanged` parameters
    - Render three pill-shaped options using `AuthService.validUsers`
    - Highlight selected user with `AppColors.primaryLight` background and `AppColors.primary` border/text
    - Unselected pills use transparent background with `AppColors.border` border
    - Initialize selection from `authService.currentUser`
    - On tap: call `authService.setUser(userId)` and `onChanged?.call(userId)`
    - Use font size 11, `FontWeight.w500`, `BorderRadius.circular(20)` — matching `FamiliarityPills` pattern
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 6.2_

  - [x] 2.2 Integrate `UserSelectorWidget` into `lib/screens/entry_screen.dart`
    - Add an `AuthService` instance field in `_EntryScreenState`
    - Add a `MOCK USER` label using `AppTextStyles.label` above the selector
    - Place `UserSelectorWidget` above the existing typeahead input field (below the heading, above the text input)
    - Pass the `AuthService` instance to the widget
    - _Requirements: 6.1, 6.2_

  - [ ]* 2.3 Write widget tests for UserSelectorWidget
    - Create `test/widgets/user_selector_test.dart`
    - Test that exactly three options are rendered with correct labels
    - Test that `demo-user-1` is selected by default
    - Test that tapping a different user updates the selection
    - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [x] 3. Update SessionService to use AuthService
  - [x] 3.1 Modify `lib/services/session_service.dart` to accept `AuthService` dependency
    - Add `final AuthService _authService` field
    - Add constructor parameter: `SessionService({required AuthService authService})`
    - Replace hardcoded `'Authorization': 'Bearer demo-user-1'` with `_authService.getAuthHeader()`
    - _Requirements: 3.1, 3.2_

  - [x] 3.2 Update `lib/screens/entry_screen.dart` to pass `AuthService` to `SessionService`
    - Change `SessionService()` instantiation to `SessionService(authService: _authService)` using the same `AuthService` instance shared with `UserSelectorWidget`
    - _Requirements: 3.1, 3.2_

  - [ ]* 3.3 Write property test for dynamic auth header in SessionService
    - Create `test/services/session_service_auth_property_test.dart`
    - **Property 3: SessionService uses dynamic auth header**
    - For each valid user, set it in AuthService, call `SessionService.prepare()` with a mock client, capture the request, assert Authorization header matches `getAuthHeader()`
    - **Validates: Requirements 3.1, 3.2**

- [x] 4. Implement backend token extraction
  - [x] 4.1 Create `backend/utils/auth.mjs` with shared auth utility
    - Export `const VALID_USERS = ['demo-user-1', 'demo-user-2', 'demo-user-3']`
    - Export `function extractUserId(event)` that:
      - Reads `Authorization` or `authorization` header from `event.headers`
      - Returns `{ statusCode: 401, body: JSON.stringify({ error: 'Authentication required' }) }` if header is missing
      - Strips `Bearer ` prefix to get the token
      - Returns `{ statusCode: 403, body: JSON.stringify({ error: 'Invalid user' }) }` if token is not in `VALID_USERS`
      - Returns `{ userId: token }` on success
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 5.1, 5.2_

  - [x] 4.2 Integrate `extractUserId` into existing Lambda handler(s)
    - Import `extractUserId` from `./utils/auth.mjs`
    - Call `extractUserId(event)` at the top of each handler
    - If result has `statusCode`, return it immediately as the response
    - Otherwise use `result.userId` in handler logic
    - _Requirements: 4.4_

  - [ ]* 4.3 Write property test for token extraction round trip
    - Create `backend/test/auth.property.test.mjs`
    - **Property 4: Token extraction round trip**
    - For each valid user ID, construct event with `Authorization: Bearer <userId>`, call `extractUserId`, assert `userId` field matches
    - **Validates: Requirements 4.1, 4.4**

  - [ ]* 4.4 Write property test for invalid token rejection
    - Add to `backend/test/auth.property.test.mjs`
    - **Property 5: Invalid token rejection**
    - Generate random strings excluding valid IDs, construct event, call `extractUserId`, assert 403 response
    - **Validates: Requirements 4.3**

  - [ ]* 4.5 Write unit tests for extractUserId
    - Create `backend/test/auth.test.mjs`
    - Test 401 when Authorization header is missing
    - Test 403 for invalid token value
    - Test case-insensitive header name handling (`authorization` vs `Authorization`)
    - Test VALID_USERS contains exactly the three expected IDs
    - _Requirements: 4.2, 4.3, 5.1_

- [x] 5. Final checkpoint
  - Run `flutter test` and verify frontend tests pass
  - Run backend tests and verify they pass
  - Verify `AuthService` defaults to `demo-user-1`
  - Verify `UserSelectorWidget` appears on Entry Screen above input fields
  - Verify `SessionService` no longer has hardcoded auth token

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Frontend property tests use the `glados` package (already in dev_dependencies)
- Backend property tests use `fast-check`
- The `UserSelectorWidget` follows the same visual pattern as `FamiliarityPills`
- `SessionService` constructor change is a breaking change — all instantiation sites must be updated
