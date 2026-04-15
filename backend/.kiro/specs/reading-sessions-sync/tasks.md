# Implementation Plan: Reading Sessions Sync

## Overview

Add fire-and-forget sync to the Quran.com Reading Sessions API (prelive environment) after every session is created in DynamoDB. All new functions (`getPreliveAccessToken`, `syncReadingSession`, `resolveChapterAndVerse`) are added to `src/sessions.mjs`. The existing `createSession` function is modified to call the sync after DynamoDB writes. Property-based and unit tests validate correctness.

## Tasks

- [x] 1. Implement prelive OAuth2 token acquisition
  - [x] 1.1 Add `getPreliveAccessToken` function to `src/sessions.mjs`
    - Add module-level variables `cachedPreliveToken` and `preliveTokenExpiresAt` (independent from existing `cachedToken`/`tokenExpiresAt`)
    - Implement `getPreliveAccessToken()` that always targets `https://prelive-oauth2.quran.foundation/oauth2/token` regardless of `QF_ENV`
    - Use `QF_CLIENT_ID` and `QF_CLIENT_SECRET` from `process.env` for Basic auth (same pattern as existing `getAccessToken()`)
    - Cache token in memory, refresh 60 seconds before expiry
    - Log error status and response body on non-success, then throw a descriptive error
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 5.2_

  - [ ]* 1.2 Write property test: Prelive token caching is independent from production token
    - **Property 4: Prelive token caching is independent from production token**
    - Generate random sequences of `getAccessToken()` and `getPreliveAccessToken()` calls with random token values; verify each cache returns its own token independently
    - **Validates: Requirements 1.3, 1.4**

  - [ ]* 1.3 Write property test: Environment isolation — prelive sync always uses prelive URLs
    - **Property 5: Environment isolation — prelive sync always uses prelive URLs**
    - Generate random `QF_ENV` values; mock fetch to capture URLs; verify prelive functions always use prelive URLs and production functions use `QF_ENV`-based URLs
    - **Validates: Requirements 5.1, 5.2, 5.3**

  - [ ]* 1.4 Write property test: Prelive auth error signaling
    - **Property 6: Prelive auth error signaling**
    - Generate random non-success HTTP status codes (400–599); mock fetch to return that status; verify `getPreliveAccessToken()` throws
    - **Validates: Requirements 1.5**

- [x] 2. Implement chapter and verse resolution
  - [x] 2.1 Add `resolveChapterAndVerse` function to `src/sessions.mjs`
    - If `surah` is provided: return `{ chapterNumber: Number(surah), verseNumber: 1 }`
    - If `pages` is provided: call `parsePageRange(pages)` to get the first page, call `fetchVersesForPage(firstPage)`, parse the first verse's `verse_key` (`"chapter:verse"`) into `{ chapterNumber, verseNumber }`
    - Throw if resolution fails (no verses returned, invalid verse_key format, etc.)
    - _Requirements: 2.3, 2.4, 4.1, 4.2_

  - [ ]* 2.2 Write property test: Surah resolution returns chapter number with verse 1
    - **Property 1: Surah resolution returns chapter number with verse 1**
    - Generate random integers >= 1 as surah numbers; verify `resolveChapterAndVerse(surah, undefined)` returns `{ chapterNumber: surah, verseNumber: 1 }`
    - **Validates: Requirements 2.3**

  - [ ]* 2.3 Write property test: Verse key parsing extracts correct chapter and verse from first page
    - **Property 2: Verse key parsing extracts correct chapter and verse from first page**
    - Generate random verse keys in `"{int}:{int}"` format; mock `fetchVersesForPage` to return a verse with that key; verify parsed chapter and verse match
    - **Validates: Requirements 2.4, 4.1**

- [x] 3. Implement sync to Reading Sessions API
  - [x] 3.1 Add `syncReadingSession` function to `src/sessions.mjs`
    - Send `POST` to `https://apis-prelive.quran.foundation/auth/v1/reading-sessions` with JSON body `{ chapterNumber, verseNumber }`
    - Include headers: `x-auth-token` (from `getPreliveAccessToken()`), `x-client-id` (`process.env.QF_CLIENT_ID`), `Content-Type: application/json`
    - Wrap entire flow in try/catch — log errors with `console.error` but never throw
    - Log HTTP error status and response body on non-success responses
    - Log network/timeout error details
    - _Requirements: 2.1, 2.2, 2.5, 3.1, 3.2, 5.1_

  - [ ]* 3.2 Write unit tests for `syncReadingSession`
    - Test that POST is sent to correct prelive URL with correct headers and JSON body
    - Test that HTTP 500 from Reading Sessions API is logged and swallowed
    - Test that network error is logged and swallowed
    - _Requirements: 2.1, 2.2, 2.5, 3.1, 3.2_

- [x] 4. Wire sync into `createSession` flow
  - [x] 4.1 Modify `createSession` in `src/sessions.mjs` to call sync after DynamoDB writes
    - After existing `putItem` (session) and keyword upserts, add a try/catch block
    - Call `resolveChapterAndVerse(surah, pages)` then `syncReadingSession(chapterNumber, verseNumber)`
    - Catch all errors, log with `console.error("Reading session sync failed:", err)`, and continue
    - Return 201 response unchanged regardless of sync outcome
    - _Requirements: 2.1, 3.3, 3.4, 4.3_

  - [ ]* 4.2 Write property test: Sync failure never affects createSession response
    - **Property 3: Sync failure never affects createSession response**
    - Generate random error types (Error, TypeError, network errors); mock sync internals to throw; verify `createSession()` still returns 201
    - **Validates: Requirements 3.3, 3.4, 4.3**

  - [ ]* 4.3 Write unit tests for createSession sync integration
    - Test that `createSession` calls `syncReadingSession` after DynamoDB writes succeed
    - Test that `resolveChapterAndVerse` with pages calls `fetchVersesForPage` with first page number
    - Test that content API returning empty verses array results in sync being skipped gracefully
    - _Requirements: 2.1, 4.2, 4.3_

  - [ ]* 4.4 Write unit test for `getPreliveAccessToken`
    - Test that `getPreliveAccessToken` calls prelive auth server with correct client credentials
    - _Requirements: 1.1, 1.2_

- [x] 5. Final checkpoint
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- All new code goes in `src/sessions.mjs` — no new files except test files
- Property tests go in `tests/property/reading-sessions-sync.property.test.mjs`
- Unit tests go in `tests/unit/reading-sessions-sync.test.mjs`
- Property tests validate universal correctness properties from the design document
- No secrets are hardcoded — all credentials come from `process.env`
