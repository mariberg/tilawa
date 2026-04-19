# Requirements Document

## Introduction

This document defines the requirements for integrating the Quran Foundation Activity Days API into the existing session creation flow. When a user completes a reading session (POST /sessions), the backend already syncs to the Reading Sessions API. This feature adds a parallel fire-and-forget call to `POST /v1/activity-days` on the pre-production endpoint, recording the user's daily Quran reading activity including duration and verse ranges.

The Activity Days API lives at `https://apis-prelive.quran.foundation/auth/v1/activity-days` and requires the user's access token (not client credentials), the prelive client ID, a type of "QURAN", the session duration in seconds, verse ranges in `chapter:startVerse-chapter:endVerse` format, and a mushafId. The mushafId is hardcoded to 4 (UthmaniHafs) because the frontend does not track which mushaf the user reads from. The optional `x-timezone` header is omitted for now since the frontend does not provide timezone information.

## Glossary

- **Activity_Days_API**: The Quran Foundation pre-production endpoint `POST /v1/activity-days` at `https://apis-prelive.quran.foundation/auth/v1/activity-days`
- **Activity_Day_Sync**: The module responsible for building the request payload and making the authenticated HTTP call to the Activity_Days_API
- **Create_Session_Flow**: The existing `createSession` function in `sessions.mjs` that persists a completed session to DynamoDB and syncs to the Reading Sessions API
- **Verse_Range**: A string in the format `chapter:startVerse-chapter:endVerse` representing the span of verses covered in a session (e.g. `2:1-2:5`)
- **Resolve_Chapter_And_Verse**: The existing function in `sessions.mjs` that maps surah or page input to a chapter number and verse number
- **User_Access_Token**: The OAuth2 access token belonging to the authenticated user, passed via the `x-auth-token` header
- **QF_PRELIVE_CLIENT_ID**: Environment variable holding the Quran Foundation prelive OAuth2 client ID, passed via the `x-client-id` header
- **MushafId**: An integer identifying the Quran text edition; hardcoded to 4 (UthmaniHafs) for this integration
- **Reading_Sessions_Sync**: The existing fire-and-forget call to `POST /v1/reading-sessions` that runs alongside the Activity_Day_Sync

## Requirements

### Requirement 1: Expand Verse Resolution to Return Start and End Verse Keys

**User Story:** As a backend developer, I want `resolveChapterAndVerse` to return both start and end verse keys, so that the Activity Days API can receive the full verse range covered by a session.

#### Acceptance Criteria

1. WHEN a session is created with a `surah` field, THE Resolve_Chapter_And_Verse function SHALL return a start verse key of `{surah}:1` and an end verse key of `{surah}:1`
2. WHEN a session is created with a `pages` field, THE Resolve_Chapter_And_Verse function SHALL fetch verses for the first page and the last page in the page range
3. WHEN a session is created with a `pages` field, THE Resolve_Chapter_And_Verse function SHALL return the verse key of the first verse on the first page as the start verse key
4. WHEN a session is created with a `pages` field, THE Resolve_Chapter_And_Verse function SHALL return the verse key of the last verse on the last page as the end verse key
5. THE Resolve_Chapter_And_Verse function SHALL continue to return `chapterNumber` and `verseNumber` (derived from the start verse key) so that the existing Reading_Sessions_Sync is unaffected

### Requirement 2: Build Activity Day Request Payload

**User Story:** As a backend developer, I want the system to construct a valid Activity Days API request body from session data, so that the user's reading activity is recorded correctly.

#### Acceptance Criteria

1. THE Activity_Day_Sync SHALL set the `type` field to the string `"QURAN"` in every request body
2. THE Activity_Day_Sync SHALL set the `seconds` field to the `durationSecs` value from the session, ensuring the value is an integer greater than or equal to 1
3. THE Activity_Day_Sync SHALL set the `ranges` field to an array containing a single string in the format `startChapter:startVerse-endChapter:endVerse` derived from the resolved start and end verse keys
4. THE Activity_Day_Sync SHALL set the `mushafId` field to the integer 4 (UthmaniHafs)
5. THE Activity_Day_Sync SHALL omit the `date` field from the request body, allowing the API to default to the current date

### Requirement 3: Send Activity Day Request to the API

**User Story:** As a user, I want my daily Quran reading activity to be recorded on Quran.com when I complete a session, so that my activity streak and history are tracked.

#### Acceptance Criteria

1. WHEN a session is successfully persisted to DynamoDB in the Create_Session_Flow, THE Activity_Day_Sync SHALL send a POST request to the Activity_Days_API
2. THE Activity_Day_Sync SHALL include the `x-auth-token` header set to the User_Access_Token in every request to the Activity_Days_API
3. THE Activity_Day_Sync SHALL include the `x-client-id` header set to the value of the QF_PRELIVE_CLIENT_ID environment variable in every request to the Activity_Days_API
4. THE Activity_Day_Sync SHALL include the `Content-Type` header set to `application/json` in every request to the Activity_Days_API
5. THE Activity_Day_Sync SHALL omit the `x-timezone` header from requests to the Activity_Days_API

### Requirement 4: Fire-and-Forget Error Handling

**User Story:** As a backend developer, I want Activity Days sync failures to be handled gracefully, so that an API outage does not prevent users from creating local sessions.

#### Acceptance Criteria

1. IF the User_Access_Token is missing or empty, THEN THE Activity_Day_Sync SHALL log a warning and skip the sync without affecting the Create_Session_Flow response
2. IF the `durationSecs` value is less than 1 or not a valid integer, THEN THE Activity_Day_Sync SHALL log a warning and skip the sync without affecting the Create_Session_Flow response
3. IF the Activity_Days_API returns a non-success HTTP status, THEN THE Activity_Day_Sync SHALL log the error status and response body without throwing an exception
4. IF the Activity_Days_API request fails due to a network error or timeout, THEN THE Activity_Day_Sync SHALL log the error details without throwing an exception
5. IF the verse range resolution fails, THEN THE Activity_Day_Sync SHALL log the error and skip the sync without affecting the Create_Session_Flow response
6. THE Create_Session_Flow SHALL execute the Activity_Day_Sync and the Reading_Sessions_Sync independently, so that a failure in one does not prevent the other from executing

### Requirement 5: Integration with Existing Create Session Flow

**User Story:** As a backend developer, I want the Activity Days sync to integrate cleanly into the existing session creation flow, so that the codebase remains maintainable and the existing Reading Sessions sync is unaffected.

#### Acceptance Criteria

1. THE Create_Session_Flow SHALL call the Activity_Day_Sync after persisting the session to DynamoDB, alongside the existing Reading_Sessions_Sync
2. THE Create_Session_Flow SHALL continue to return the same response shape (`{ sessionId, createdAt }`) with status 201 regardless of Activity_Day_Sync outcome
3. THE Activity_Day_Sync SHALL use the same pre-production API base URL `https://apis-prelive.quran.foundation` as the Reading_Sessions_Sync
4. THE Activity_Day_Sync SHALL reuse the existing QF_PRELIVE_CLIENT_ID environment variable for the `x-client-id` header
