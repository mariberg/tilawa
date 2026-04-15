# Requirements Document

## Introduction

This document defines the requirements for syncing completed recitation sessions with the Quran.com Reading Sessions API. When a user completes a session and it is persisted to DynamoDB, the backend shall also create a corresponding reading session on Quran.com via their pre-production API. This enables the user's recitation history to be reflected on the Quran.com platform.

The Quran.com Reading Sessions API uses a separate pre-production environment (`apis-prelive.quran.foundation`) from the content API which uses production (`apis.quran.foundation`). Authentication uses the same OAuth2 client credentials flow but may require a different scope. The API deduplicates sessions within a 20-minute window — if a session already exists, it updates the latest read ayah instead of creating a new one.

## Glossary

- **Session_Sync_Client**: The module responsible for making authenticated HTTP requests to the Quran.com Reading Sessions API
- **Reading_Sessions_API**: The Quran.com pre-production endpoint `POST /v1/reading-sessions` at `https://apis-prelive.quran.foundation/auth/v1/reading-sessions`
- **Content_API**: The existing Quran.com production API at `https://apis.quran.foundation` used for fetching verse content
- **Prelive_Token**: An OAuth2 access token obtained from the pre-production auth server (`prelive-oauth2.quran.foundation`) with the scope required by the Reading_Sessions_API
- **Production_Token**: The existing OAuth2 access token obtained from the production auth server used by the Content_API
- **Create_Session_Flow**: The existing `createSession` function in `sessions.mjs` that persists a completed session to DynamoDB
- **Chapter_Number**: An integer (>= 1) identifying a Quran chapter (surah), sent in the Reading_Sessions_API request body as `chapterNumber`
- **Verse_Number**: An integer (>= 1) identifying a verse within a chapter, sent in the Reading_Sessions_API request body as `verseNumber`
- **QF_CLIENT_ID**: Environment variable holding the Quran Foundation OAuth2 client ID
- **QF_CLIENT_SECRET**: Environment variable holding the Quran Foundation OAuth2 client secret

## Requirements

### Requirement 1: Separate OAuth2 Token for Pre-Production Environment

**User Story:** As a backend developer, I want the system to obtain a separate OAuth2 token for the pre-production environment, so that the reading sessions sync can authenticate independently from the content API.

#### Acceptance Criteria

1. THE Session_Sync_Client SHALL obtain an OAuth2 access token from the pre-production auth server at `https://prelive-oauth2.quran.foundation/oauth2/token` using the client credentials flow
2. THE Session_Sync_Client SHALL use QF_CLIENT_ID and QF_CLIENT_SECRET environment variables for authentication with the pre-production auth server
3. THE Session_Sync_Client SHALL cache the Prelive_Token in memory and reuse the Prelive_Token until 60 seconds before the Prelive_Token expiry time
4. THE Session_Sync_Client SHALL maintain the Prelive_Token cache independently from the Production_Token cache used by the Content_API
5. IF the pre-production auth server returns a non-success response, THEN THE Session_Sync_Client SHALL log the error status and response body and throw a descriptive error

### Requirement 2: Sync Session to Quran.com Reading Sessions API

**User Story:** As a user, I want my completed recitation sessions to be synced to Quran.com, so that my reading history is tracked on the platform.

#### Acceptance Criteria

1. WHEN a session is successfully persisted to DynamoDB in the Create_Session_Flow, THE Session_Sync_Client SHALL send a POST request to the Reading_Sessions_API with the Chapter_Number and Verse_Number derived from the session data
2. THE Session_Sync_Client SHALL include the `x-auth-token` header set to the Prelive_Token and the `x-client-id` header set to QF_CLIENT_ID in every request to the Reading_Sessions_API
3. WHEN the request body contains a `surah` field, THE Session_Sync_Client SHALL use the `surah` value as the Chapter_Number and set Verse_Number to 1
4. WHEN the request body contains a `pages` field instead of `surah`, THE Session_Sync_Client SHALL resolve the page range to a chapter number and verse number using the first page in the range
5. THE Session_Sync_Client SHALL send the request body to the Reading_Sessions_API as JSON with the shape `{ "chapterNumber": integer, "verseNumber": integer }`

### Requirement 3: Error Handling for Reading Sessions Sync

**User Story:** As a backend developer, I want sync failures to be handled gracefully, so that a Quran.com API outage does not prevent users from creating local sessions.

#### Acceptance Criteria

1. IF the Reading_Sessions_API returns a non-success HTTP status (400, 401, 403, 404, 422, 429, 500, 502, 503, 504), THEN THE Session_Sync_Client SHALL log the error status and response body
2. IF the Reading_Sessions_API request fails due to a network error or timeout, THEN THE Session_Sync_Client SHALL log the error details
3. IF the sync to the Reading_Sessions_API fails for any reason, THEN THE Create_Session_Flow SHALL still return a successful response to the client with the DynamoDB session data
4. IF the Prelive_Token acquisition fails, THEN THE Session_Sync_Client SHALL log the error and skip the sync without affecting the Create_Session_Flow response

### Requirement 4: Page-to-Chapter Resolution

**User Story:** As a backend developer, I want to resolve Mushaf page numbers to chapter and verse references, so that page-based sessions can be synced to the Reading_Sessions_API which requires chapter and verse numbers.

#### Acceptance Criteria

1. WHEN a session is created with a `pages` field, THE Session_Sync_Client SHALL determine the Chapter_Number and Verse_Number corresponding to the first page in the page range
2. THE Session_Sync_Client SHALL use the Quran.com Content_API `verses/by_page/{page}` endpoint to resolve the first page to a chapter and verse reference
3. IF the page-to-chapter resolution fails, THEN THE Session_Sync_Client SHALL log the error and skip the sync without affecting the Create_Session_Flow response

### Requirement 5: Environment Configuration

**User Story:** As a backend developer, I want the reading sessions sync to use the pre-production API environment, so that the integration works within the constraints of the Quran.com API availability.

#### Acceptance Criteria

1. THE Session_Sync_Client SHALL use the pre-production API base URL `https://apis-prelive.quran.foundation` for all Reading_Sessions_API requests, regardless of the QF_ENV environment variable value
2. THE Session_Sync_Client SHALL use the pre-production auth base URL `https://prelive-oauth2.quran.foundation` for obtaining the Prelive_Token, regardless of the QF_ENV environment variable value
3. THE Content_API SHALL continue to use the environment specified by the QF_ENV environment variable (production) without any changes
