# Implementation Plan: Activity Day Sync

## Overview

Add a second fire-and-forget sync to the `createSession()` flow in `src/sessions.mjs`. After persisting a session to DynamoDB, the system already syncs to the Reading Sessions API. This feature adds a parallel call to the Activity Days API (`POST /auth/v1/activity-days`) on the prelive endpoint, recording the user's daily reading activity with duration and verse ranges. The `resolveChapterAndVerse` function is expanded to return `startVerseKey` and `endVerseKey` alongside the existing fields.

## Tasks

- [x] 1. Expand `resolveChapterAndVerse` to return verse keys
  - [x] 1.1 Modify `resolveChapterAndVerse` in `src/sessions.mjs` to return `startVerseKey` and `endVerseKey`
    - Surah path: return `{ chapterNumber: Number(surah), verseNumber: 1, startVerseKey: "{surah}:1", endVerseKey: "{surah}:1" }`
    - Pages path: fetch verses for the first page AND the last page via `fetchVersesForPage`
    - Set `startVerseKey` to the `verseKey` of the first verse on the first page
    - Set `endVerseKey` to the `verseKey` of the last verse on the last page
    - `chapterNumber` and `verseNumber` remain derived from the start verse key (preserving existing `syncReadingSession` behavior)
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

  - [ ]* 1.2 Write property test: Surah resolution returns consistent verse keys and chapter/verse
    - **Property 1: Surah resolution returns consistent verse keys and chapter/verse**
    - Generate random integers 1–114 as surah numbers; verify all four return fields (`chapterNumber`, `verseNumber`, `startVerseKey`, `endVerseKey`)
    - **Validates: Requirements 1.1, 1.5**

  - [ ]* 1.3 Write property test: Page resolution returns correct start and end verse keys
    - **Property 2: Page resolution returns correct start and end verse keys**
    - Generate random page range strings and random verse key arrays; mock `fetchVersesForPage` to return them; verify `startVerseKey`, `endVerseKey`, `chapterNumber`, `verseNumber`
    - **Validates: Requirements 1.2, 1.3, 1.4, 1.5**

- [x] 2. Implement `syncActivityDay` function
  - [x] 2.1 Add `syncActivityDay` function to `src/sessions.mjs`
    - Validate `userAccessToken` is present — log warning and return early if missing/empty
    - Validate `durationSecs` is an integer >= 1 — log warning and return early if invalid
    - Send `POST` to `https://apis-prelive.quran.foundation/auth/v1/activity-days`
    - Headers: `x-auth-token` (user token), `x-client-id` (`process.env.QF_PRELIVE_CLIENT_ID`), `Content-Type: application/json`
    - No `x-timezone` header
    - Body: `{ type: "QURAN", seconds: durationSecs, ranges: ["{startVerseKey}-{endVerseKey}"], mushafId: 4 }`
    - Wrap entire flow in try/catch — log and swallow all errors
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 3.1, 3.2, 3.3, 3.4, 3.5, 4.1, 4.2, 4.3, 4.4_

  - [ ]* 2.2 Write property test: Payload constant fields invariant
    - **Property 3: Payload constant fields invariant**
    - Generate random valid inputs; mock fetch to capture request body; verify `type === "QURAN"`, `mushafId === 4`, and absence of `date` field
    - **Validates: Requirements 2.1, 2.4, 2.5**

  - [ ]* 2.3 Write property test: Payload seconds and range formatting
    - **Property 4: Payload seconds and range formatting**
    - Generate random `durationSecs` (>= 1) and random verse key pairs; mock fetch to capture body; verify `seconds` equals `durationSecs` and `ranges` contains exactly one string `"{startVerseKey}-{endVerseKey}"`
    - **Validates: Requirements 2.2, 2.3**

  - [ ]* 2.4 Write property test: Invalid durationSecs skips sync
    - **Property 5: Invalid durationSecs skips sync**
    - Generate random invalid `durationSecs` values (0, negatives, floats, NaN, null, undefined); mock fetch; verify fetch is never called and no exception is thrown
    - **Validates: Requirements 4.2**

  - [ ]* 2.5 Write property test: Sync failure never throws
    - **Property 6: Sync failure never throws**
    - Generate random error types (HTTP error statuses, network errors, timeouts); mock fetch to fail; verify `syncActivityDay` resolves without throwing
    - **Validates: Requirements 4.3, 4.4**

  - [ ]* 2.6 Write unit tests for `syncActivityDay`
    - Test POST is sent to correct prelive URL with correct headers (`x-auth-token`, `x-client-id`, `Content-Type`)
    - Test `x-timezone` header is omitted
    - Test sync is skipped when `userAccessToken` is missing
    - Test sync is skipped when `userAccessToken` is empty string
    - Test `QF_PRELIVE_CLIENT_ID` is used for `x-client-id` header
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 4.1, 5.3, 5.4_

- [x] 3. Checkpoint — Verify verse resolution and syncActivityDay
  - Ensure all tests pass, ask the user if questions arise.

- [x] 4. Wire `syncActivityDay` into `createSession`
  - [x] 4.1 Modify `createSession` in `src/sessions.mjs` to call both syncs independently
    - Destructure `{ chapterNumber, verseNumber, startVerseKey, endVerseKey }` from `resolveChapterAndVerse`
    - Wrap each sync in its own try/catch so failures are independent
    - Call `syncReadingSession(chapterNumber, verseNumber, userAccessToken)` in one try/catch
    - Call `syncActivityDay(startVerseKey, endVerseKey, durationSecs, userAccessToken)` in a separate try/catch
    - Wrap both in an outer try/catch for verse resolution failure (skips both syncs, logs error)
    - Return 201 with `{ sessionId, createdAt }` unchanged regardless of sync outcomes
    - _Requirements: 4.5, 4.6, 5.1, 5.2_

  - [ ]* 4.2 Write property test: Sync independence
    - **Property 7: Sync independence**
    - Generate random success/failure combinations for both syncs; mock both API calls; verify both are attempted regardless of the other's outcome
    - **Validates: Requirements 4.6**

  - [ ]* 4.3 Write property test: createSession always returns 201 regardless of sync outcome
    - **Property 8: createSession always returns 201 regardless of sync outcome**
    - Generate random errors at various points (resolution, reading sync, activity sync); verify `createSession` returns 201 with correct shape after DynamoDB write succeeds
    - **Validates: Requirements 4.5, 5.1, 5.2**

  - [ ]* 4.4 Write unit tests for createSession sync integration
    - Test that `createSession` calls both syncs after DynamoDB write
    - Test that `resolveChapterAndVerse` with single page returns same page for start and end
    - _Requirements: 5.1_

- [x] 5. Final checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- All new code goes in `src/sessions.mjs` — no new files except test files
- Property tests go in `tests/property/activity-day-sync.property.test.mjs`
- Unit tests go in `tests/unit/activity-day-sync.test.mjs`
- Property tests validate universal correctness properties from the design document
- No secrets are hardcoded — all credentials come from `process.env`
- `mushafId` is hardcoded to 4 (UthmaniHafs) as specified in requirements
