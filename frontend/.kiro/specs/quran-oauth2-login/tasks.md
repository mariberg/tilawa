# Implementation Plan: Quran OAuth2 Login

## Overview

Replace local `.env` credential-based authentication with Quran.com's hosted OAuth2 login UI. The implementation proceeds incrementally: environment config first, then core AuthService OAuth2 logic, JWT helper, AuthScreen UI swap, SessionService header migration, EntryScreen logout, and finally wiring and integration tests. Existing mock auth code is commented out (not deleted) throughout.

## Tasks

- [x] 1. Update `.env` and add JWT decode helper
  - [x] 1.1 Update `.env` with OAuth2 configuration
    - Add `TOKEN_HOST`, `CLIENT_ID`, `CLIENT_SECRET`, `SCOPES`, `SESSION_SECRET` entries
    - Comment out `LOGIN_USER_1` through `LOGIN_PASS_3` with a comment explaining they are replaced by OAuth2 authentication
    - Keep `BASE_URL` and `API_KEY` unchanged
    - _Requirements: 1.1, 1.2, 1.3, 1.4_

  - [x] 1.2 Create JWT decode helper utility
    - Create `lib/utils/jwt_utils.dart` with `decodeJwtPayload(String jwt)` function
    - Split JWT on `.`, base64url-decode the payload segment, return decoded JSON map
    - Throw `FormatException` if JWT does not have exactly 3 parts
    - No signature verification (token received over HTTPS directly from provider)
    - _Requirements: 5.1_

  - [ ]* 1.3 Write property test for JWT decode round trip
    - **Property 6: JWT payload decode round trip**
    - **Validates: Requirements 5.1, 5.2, 5.3**

- [x] 2. Refactor AuthService for OAuth2
  - [x] 2.1 Comment out existing mock auth code in AuthService
    - Comment out `validUsers`, `defaultUser`, `_currentUser`, `currentUser` getter, `validate()`, `setUser()`, and `getAuthHeader()` with explanatory comments stating they are replaced by OAuth2 authentication
    - _Requirements: 2.1, 2.2, 6.3_

  - [x] 2.2 Add OAuth2 fields and constructor to AuthService
    - Add `_tokenHost`, `_clientId`, `_clientSecret`, `_scopes` fields read from `.env` via `dotenv.env`
    - Add `_accessToken`, `_idToken`, `_refreshToken`, `_tokenExpiry` nullable fields
    - Add `_userProfile` map and `_pendingState` string for CSRF
    - Add `isAuthenticated` getter and `userProfile` getter
    - Accept an optional `http.Client` parameter for testability
    - _Requirements: 1.5_

  - [x] 2.3 Implement `buildAuthorizationUrl()` method
    - Build URL `{TOKEN_HOST}/oauth2/auth` with query params: `client_id`, `redirect_uri`, `response_type=code`, `scope`, `state`
    - Generate cryptographically random state parameter and store in `_pendingState`
    - Return a record `({String url, String state})`
    - _Requirements: 3.2, 3.3_

  - [ ]* 2.4 Write property tests for authorization URL
    - **Property 1: Authorization URL contains all required parameters**
    - **Validates: Requirements 3.2, 3.3**

  - [ ]* 2.5 Write property test for state uniqueness
    - **Property 2: State parameter uniqueness**
    - **Validates: Requirements 3.2**

  - [x] 2.6 Implement `handleCallback()` method
    - Verify returned `state` matches `_pendingState`; throw on mismatch
    - POST to `{TOKEN_HOST}/oauth2/token` with `grant_type=authorization_code`, `code`, `redirect_uri`, `client_id`, `client_secret` as form-encoded body
    - Parse response JSON; store `access_token`, `id_token`, `refresh_token`, compute `_tokenExpiry` from `expires_in`
    - Decode `id_token` via `decodeJwtPayload()` and store user profile (`sub`, `name`, `email`)
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 5.2, 5.3_

  - [ ]* 2.7 Write property test for state verification
    - **Property 3: State verification — matching state succeeds, mismatched state rejects**
    - **Validates: Requirements 4.1, 4.2**

  - [ ]* 2.8 Write property test for token exchange request formation
    - **Property 4: Token exchange request formation**
    - **Validates: Requirements 4.3**

  - [ ]* 2.9 Write property test for token storage after exchange
    - **Property 5: Successful token exchange stores all tokens**
    - **Validates: Requirements 4.4**

  - [x] 2.10 Implement `getAuthHeaders()` method
    - Check if token is expired or within 60 seconds of expiry; if so, call `refreshAccessToken()` first
    - Return `{'x-auth-token': _accessToken, 'x-client-id': _clientId}`
    - _Requirements: 6.1, 7.1_

  - [ ]* 2.11 Write property test for auth headers
    - **Property 7: Auth headers contain correct token and client ID**
    - **Validates: Requirements 6.1**

  - [x] 2.12 Implement `refreshAccessToken()` method
    - POST to `{TOKEN_HOST}/oauth2/token` with `grant_type=refresh_token`, `refresh_token`, `client_id`, `client_secret`
    - On success, update `_accessToken`, `_idToken` (if returned), `_refreshToken` (if rotated), `_tokenExpiry`
    - On failure, clear all tokens and user profile
    - _Requirements: 7.1, 7.2, 7.3_

  - [ ]* 2.13 Write property test for expired token refresh
    - **Property 8: Expired token triggers refresh before returning headers**
    - **Validates: Requirements 7.1, 7.2**

  - [ ]* 2.14 Write property test for failed refresh clearing tokens
    - **Property 9: Failed refresh clears all tokens**
    - **Validates: Requirements 7.3**

  - [x] 2.15 Implement `logout()` method
    - Store `_idToken` for the hint before clearing
    - Clear `_accessToken`, `_idToken`, `_refreshToken`, `_tokenExpiry`, `_userProfile`
    - Return logout URL: `{TOKEN_HOST}/oauth2/sessions/logout?post_logout_redirect_uri={uri}&id_token_hint={idToken}`
    - _Requirements: 8.2, 8.3_

  - [ ]* 2.16 Write property test for logout
    - **Property 10: Logout clears all tokens and builds correct logout URL**
    - **Validates: Requirements 8.2, 8.3**

- [x] 3. Checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 4. Refactor AuthScreen for OAuth2 login UI
  - [x] 4.1 Comment out existing mock auth UI code in AuthScreen
    - Comment out `_usernameController`, `_passwordController`, `_obscurePassword`, `_isButtonEnabled`, `_onFieldChanged()`, `_inputDecoration()`, username/password text fields, visibility toggle, "Sign in" button logic, "Forgot password?" link, and "Sign up" hint row
    - Add explanatory comments stating they are replaced by the OAuth2 login flow
    - _Requirements: 2.3, 2.4_

  - [x] 4.2 Implement OAuth2 login flow in AuthScreen
    - Add `_isLoading` bool and `_errorMessage` string state
    - Add "Continue with Quran.Foundation" button styled with `AppColors.primary`
    - On tap: call `_authService.buildAuthorizationUrl()`, open URL in browser, show loading indicator
    - Handle OAuth2 callback: extract `code` and `state` from redirect URI, call `_authService.handleCallback()`
    - On success: navigate to `/home` passing `_authService` as route argument
    - On error: display error message in red text below the button; clear error on next tap
    - On cancel: return to idle state with button re-enabled
    - _Requirements: 3.1, 3.3, 3.4, 3.5, 4.1, 4.2, 4.5, 9.1, 9.2, 9.3, 9.4, 10.1_

  - [ ]* 4.3 Write unit tests for AuthScreen widget
    - Test "Continue with Quran.Foundation" button renders
    - Test loading indicator shows during auth flow
    - Test error message displays in red
    - _Requirements: 9.1, 9.2, 9.3_

- [x] 5. Update SessionService to use OAuth2 headers
  - [x] 5.1 Replace `getAuthHeader()` calls with `getAuthHeaders()` in SessionService
    - Change all four methods (`prepare`, `submitResults`, `submitFeeling`, `fetchRecentSessions`) to use `await _authService.getAuthHeaders()` instead of `_authService.getAuthHeader()`
    - Spread the returned headers map into the request headers alongside `Content-Type` and `x-api-key`
    - Remove the old `'Authorization': _authService.getAuthHeader()` line (comment it out with explanation)
    - _Requirements: 6.1, 6.2_

  - [ ]* 5.2 Write unit tests for SessionService header integration
    - Verify API calls use `x-auth-token` and `x-client-id` headers instead of `Authorization: Bearer`
    - _Requirements: 6.2_

- [x] 6. Add logout to EntryScreen
  - [x] 6.1 Add logout button to EntryScreen
    - Add a logout icon button (e.g. `Icons.logout`) in the top area of the screen
    - On tap: call `_authService!.logout(redirectUri)`, open the returned logout URL in the browser, navigate to AuthScreen
    - _Requirements: 8.1, 8.2, 8.3, 8.4_

  - [ ]* 6.2 Write unit tests for EntryScreen logout
    - Test logout icon renders
    - Test navigation to AuthScreen after logout
    - _Requirements: 8.1, 8.4_

- [x] 7. Wire navigation and add `url_launcher` dependency
  - [x] 7.1 Add `url_launcher` to `pubspec.yaml`
    - Add `url_launcher` under dependencies for opening OAuth2 URLs in the browser
    - _Requirements: 3.3_

  - [x] 7.2 Verify navigation flow passes AuthService correctly
    - Ensure AuthScreen navigates to EntryScreen with `_authService` as route argument after successful OAuth2 login
    - Ensure EntryScreen continues to extract AuthService from route arguments and passes it to SessionService
    - Ensure EntryScreen redirects to AuthScreen when arguments are missing
    - _Requirements: 10.1, 10.2, 10.3_

- [x] 8. Final checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Property tests use the `glados` package already in dev dependencies
- Existing mock auth code is commented out (not deleted) per requirements
- HTTP calls in tests should be mocked using a custom `http.Client` parameter
