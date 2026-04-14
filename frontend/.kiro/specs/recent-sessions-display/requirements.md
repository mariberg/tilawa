# Requirements Document

## Introduction

Replace the hardcoded recent session rows on the Entry Screen with live data fetched from the backend API at `GET /sessions/recent`. The response is a JSON array of session objects containing `sessionId`, `pages`, `feeling`, and `createdAt`. The Entry Screen displays these sessions in reverse-chronological order under the "CONTINUE WHERE YOU LEFT OFF" section. Sessions where the feeling is `revisit` are visually distinguished so the user knows they need more practice on that content.

## Glossary

- **Entry_Screen**: The home screen (`lib/screens/entry_screen.dart`) where users configure and start a preparation session.
- **Session_Service**: The Dart service class (`lib/services/session_service.dart`) responsible for all session-related API calls.
- **Recent_Session**: A data model representing a single item from the `GET /sessions/recent` response, containing `sessionId`, `pages`, `feeling`, and `createdAt` fields.
- **Recent_Sessions_API**: The backend REST endpoint at `GET /sessions/recent` that returns an array of recent session objects.
- **Auth_Service**: The Dart service class (`lib/services/auth_service.dart`) that provides the authorization header for API requests.
- **API_Key**: The `x-api-key` header value loaded from the `.env` file, required for all backend requests.
- **Feeling_Value**: One of three valid string values representing the user's session feedback: `smooth`, `struggled`, `revisit`.
- **Revisit_Indicator**: A visual label displayed alongside a recent session row when the session's feeling is `revisit`.

## Requirements

### Requirement 1: Fetch Recent Sessions from API

**User Story:** As a user, I want the app to load my recent sessions from the backend, so that I can see what I have practised recently.

#### Acceptance Criteria

1. THE Session_Service SHALL expose a `fetchRecentSessions` method that returns a list of Recent_Session objects.
2. WHEN `fetchRecentSessions` is called, THE Session_Service SHALL send an HTTP GET request to `{BASE_URL}/sessions/recent`.
3. WHEN `fetchRecentSessions` is called, THE Session_Service SHALL include the `Authorization` header obtained from Auth_Service and the `x-api-key` header loaded from the API_Key environment variable.
4. IF the `BASE_URL` environment variable is missing or empty, THEN THE Session_Service SHALL throw a descriptive error indicating that `BASE_URL` is not configured.
5. IF the `API_KEY` environment variable is missing or empty, THEN THE Session_Service SHALL throw a descriptive error indicating that `API_KEY` is not configured.

### Requirement 2: Parse Recent Sessions Response

**User Story:** As a developer, I want the API response parsed into structured Dart models, so that the data can be used consistently in the UI.

#### Acceptance Criteria

1. WHEN the Recent_Sessions_API returns a 200 status code, THE Session_Service SHALL parse the response body as a JSON array into a list of Recent_Session instances.
2. THE Recent_Session model SHALL contain the fields: `sessionId` (String), `pages` (String), `feeling` (String), and `createdAt` (DateTime).
3. WHEN a valid JSON array is provided, THE Recent_Session parser SHALL produce Recent_Session instances whose field values match the original JSON values exactly.
4. IF the Recent_Sessions_API returns a non-200 status code, THEN THE Session_Service SHALL throw an exception with a message that includes the status code.
5. IF the response body cannot be parsed as valid JSON, THEN THE Session_Service SHALL throw a descriptive error indicating a parsing failure.

### Requirement 3: Display Recent Sessions on Entry Screen

**User Story:** As a user, I want to see my recent sessions on the home screen, so that I can quickly see what I have been practising.

#### Acceptance Criteria

1. WHEN the Entry_Screen is loaded, THE Entry_Screen SHALL call `fetchRecentSessions` on the Session_Service to retrieve recent session data.
2. THE Entry_Screen SHALL display each Recent_Session as a row showing the pages value and a human-readable relative date derived from the `createdAt` field.
3. THE Entry_Screen SHALL display the recent sessions in the order returned by the API under the "CONTINUE WHERE YOU LEFT OFF" section.
4. WHILE the recent sessions are being fetched, THE Entry_Screen SHALL display a loading indicator in the recent sessions section.
5. IF the fetch fails, THEN THE Entry_Screen SHALL display a short error message in the recent sessions section instead of session rows.
6. IF the API returns an empty array, THEN THE Entry_Screen SHALL display a message indicating that no recent sessions are available.

### Requirement 4: Highlight Revisit Sessions

**User Story:** As a user, I want sessions marked as "revisit" to be visually distinct, so that I know which content I need to practise more.

#### Acceptance Criteria

1. WHEN a Recent_Session has a feeling value of `revisit`, THE Entry_Screen SHALL display a Revisit_Indicator label alongside that session row.
2. WHEN a Recent_Session has a feeling value other than `revisit`, THE Entry_Screen SHALL display the session row without a Revisit_Indicator.
3. THE Revisit_Indicator SHALL be visually distinct from the surrounding text so the user can identify revisit sessions at a glance.

### Requirement 5: Remove Hardcoded Recent Session Data

**User Story:** As a developer, I want the hardcoded recent session rows removed from the Entry Screen, so that the UI is driven entirely by live API data.

#### Acceptance Criteria

1. THE Entry_Screen SHALL NOT contain hardcoded recent session entries such as "Pages 50–54" or "Pages 12–15".
2. THE Entry_Screen SHALL derive all recent session rows exclusively from the data returned by the `fetchRecentSessions` method.
