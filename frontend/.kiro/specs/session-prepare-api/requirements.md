# Requirements Document

## Introduction

Add a session preparation API integration to the Quran Prep app. The app sends a POST request to a backend API at `/sessions/prepare` with either page numbers or a surah name along with a familiarity level. The API returns a session ID, an overview (list of summary sentences), and a list of keyword objects (each containing Arabic text, English translation, a hint, and a type). The API base URL is configured via an environment variable stored in a `.env` file, with a `.env.example` committed to the repository for developer onboarding.

## Glossary

- **Session_Prepare_API**: The backend REST endpoint at `POST /sessions/prepare` that accepts page numbers or a surah name and returns session preparation data.
- **Session_Service**: A Dart service class responsible for calling the Session_Prepare_API and parsing the response.
- **Session_Response**: A Dart data model representing the parsed response from the Session_Prepare_API, containing a session ID, overview list, and keywords list.
- **Keyword_Model**: A Dart data model representing a single keyword object with fields: `arabic`, `translation`, `hint`, and `type`.
- **Env_Config**: The environment configuration mechanism that loads the API base URL from a `.env` file at runtime.
- **Env_Example_File**: A `.env.example` file committed to version control containing placeholder values for required environment variables.
- **Familiarity_Level**: A string value indicating the user's familiarity with the content (e.g., "new", "review").

## Requirements

### Requirement 1: Environment Configuration

**User Story:** As a developer, I want the API base URL stored in a `.env` file, so that the endpoint can be configured per environment without code changes.

#### Acceptance Criteria

1. THE Env_Config SHALL load the API base URL from a `BASE_URL` variable defined in a `.env` file at the project root.
2. THE Env_Example_File SHALL exist at the project root as `.env.example` and contain a placeholder entry for `BASE_URL`.
3. THE project `.gitignore` SHALL include an entry for `.env` to prevent committing secrets to version control.
4. IF the `BASE_URL` variable is missing or empty in the `.env` file, THEN THE Env_Config SHALL throw a descriptive error indicating that `BASE_URL` is not configured.

### Requirement 2: Session Prepare Request

**User Story:** As a user, I want to send my selected pages or surah name to the API, so that I receive a prepared session with an overview and keywords.

#### Acceptance Criteria

1. WHEN the user initiates session preparation, THE Session_Service SHALL send an HTTP POST request to `{BASE_URL}/sessions/prepare`.
2. THE Session_Service SHALL include an `Authorization` header with the value `Bearer demo-user-1` in the request.
3. THE Session_Service SHALL send a JSON request body containing a `familiarity` field as a string.
4. WHEN the user provides page numbers, THE Session_Service SHALL include a `pages` field in the JSON request body.
5. WHEN the user provides a surah name, THE Session_Service SHALL include a `surah` field in the JSON request body.
6. THE Session_Service SHALL set the `Content-Type` header to `application/json` in the request.

### Requirement 3: Session Prepare Response Parsing

**User Story:** As a developer, I want the API response parsed into structured Dart models, so that the data can be used consistently in the app.

#### Acceptance Criteria

1. WHEN the Session_Prepare_API returns a 200 status code, THE Session_Service SHALL parse the response body into a Session_Response instance.
2. THE Session_Response SHALL contain a `sessionId` field of type String parsed from the `sessionId` JSON field.
3. THE Session_Response SHALL contain an `overview` field of type `List<String>` parsed from the `overview` JSON array.
4. THE Session_Response SHALL contain a `keywords` field of type `List<Keyword_Model>` parsed from the `keywords` JSON array.
5. THE Keyword_Model SHALL contain the fields: `arabic` (String), `translation` (String), `hint` (String), and `type` (String).
6. WHEN a valid JSON response is provided, THE Session_Response parser SHALL produce a Session_Response whose fields match the original JSON values exactly (round-trip correctness).
7. IF the JSON response is missing a required field or contains a null value for a required field, THEN THE Session_Response parser SHALL throw a descriptive error indicating which field is missing.

### Requirement 4: Error Handling

**User Story:** As a user, I want clear feedback when the session preparation fails, so that I understand what went wrong.

#### Acceptance Criteria

1. IF the Session_Prepare_API returns a non-200 status code, THEN THE Session_Service SHALL throw an exception with a message that includes the status code.
2. IF a network error occurs during the API call, THEN THE Session_Service SHALL propagate the error so the caller can handle it.
3. IF the response body cannot be parsed as valid JSON, THEN THE Session_Service SHALL throw a descriptive error indicating a parsing failure.

### Requirement 5: Request Validation

**User Story:** As a developer, I want the request validated before sending, so that invalid API calls are prevented.

#### Acceptance Criteria

1. IF neither `pages` nor `surah` is provided in the request, THEN THE Session_Service SHALL throw a descriptive error indicating that either pages or a surah name is required.
2. IF both `pages` and `surah` are provided in the request, THEN THE Session_Service SHALL throw a descriptive error indicating that only one input type is allowed per request.

### Requirement 6: Package Dependencies

**User Story:** As a developer, I want the necessary packages added to the project, so that environment loading and HTTP functionality are available.

#### Acceptance Criteria

1. THE project SHALL include the `flutter_dotenv` package (or equivalent) as a dependency in `pubspec.yaml` for loading `.env` files.
2. THE project SHALL include the `http` package as a dependency in `pubspec.yaml` for making API requests.
