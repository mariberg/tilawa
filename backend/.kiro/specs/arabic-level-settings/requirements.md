# Requirements Document

## Introduction

This feature adds a user settings system to persist the user's Arabic proficiency level. A new `/settings` API endpoint allows the frontend to submit and retrieve the user's Arabic level. The stored level is used when preparing new sessions, replacing the per-request `familiarity` field currently sent by the frontend. This ensures consistent prompt calibration across sessions and gives users a single place to manage their proficiency setting.

## Glossary

- **Settings_Endpoint**: The API route (`/settings`) that accepts and returns user settings
- **Arabic_Level**: A string enum representing the user's Arabic proficiency; one of `"new"`, `"somewhat_familiar"`, or `"well_known"`
- **Settings_Record**: A DynamoDB item storing user settings, keyed by `PK: USER#<userId>` and `SK: SETTINGS`
- **Session_Preparer**: The existing `prepareSession` function that fetches Quran content and invokes Bedrock to generate an overview and keywords
- **Router**: The request routing layer (`routeRequest`) that dispatches HTTP requests to handler functions

## Requirements

### Requirement 1: Save User Arabic Level

**User Story:** As a user, I want to submit my Arabic proficiency level through the settings endpoint, so that the system remembers my level for future sessions.

#### Acceptance Criteria

1. WHEN a PUT request is received at `/settings` with a valid JSON body containing `arabicLevel`, THE Settings_Endpoint SHALL persist a Settings_Record in DynamoDB with `PK: USER#<userId>`, `SK: SETTINGS`, and the provided `arabicLevel` value.
2. THE Settings_Endpoint SHALL accept only the following values for `arabicLevel`: `"new"`, `"somewhat_familiar"`, `"well_known"`.
3. IF the `arabicLevel` value is missing or not one of the accepted values, THEN THE Settings_Endpoint SHALL return HTTP 400 with a descriptive error message.
4. WHEN a valid Settings_Record already exists for the user and a new PUT request is received, THE Settings_Endpoint SHALL overwrite the existing `arabicLevel` value with the new value.
5. WHEN the Settings_Record is successfully saved, THE Settings_Endpoint SHALL return HTTP 200 with the saved `arabicLevel` in the response body.

### Requirement 2: Retrieve User Arabic Level

**User Story:** As a user, I want to retrieve my current Arabic level setting, so that the frontend can display my current proficiency selection.

#### Acceptance Criteria

1. WHEN a GET request is received at `/settings`, THE Settings_Endpoint SHALL retrieve the Settings_Record for the authenticated user from DynamoDB and return it with HTTP 200.
2. IF no Settings_Record exists for the user, THEN THE Settings_Endpoint SHALL return HTTP 200 with `arabicLevel` set to `null`.

### Requirement 3: Use Stored Arabic Level in Session Preparation

**User Story:** As a user, I want my stored Arabic level to be used automatically when preparing a new session, so that I do not need to specify my proficiency level every time.

#### Acceptance Criteria

1. WHEN a session preparation request is received, THE Session_Preparer SHALL fetch the user's Settings_Record from DynamoDB to obtain the stored `arabicLevel`.
2. WHEN a stored `arabicLevel` exists in the Settings_Record, THE Session_Preparer SHALL use the stored value as the familiarity level for the Bedrock prompt.
3. IF no Settings_Record exists for the user and no `familiarity` field is provided in the request body, THEN THE Session_Preparer SHALL return HTTP 400 with a descriptive error message.
4. WHEN both a stored `arabicLevel` and a request-body `familiarity` field are present, THE Session_Preparer SHALL use the stored `arabicLevel` value, ignoring the request-body `familiarity`.

### Requirement 4: Route Settings Requests

**User Story:** As a developer, I want the router to handle settings requests, so that the settings endpoint is accessible through the existing API Gateway.

#### Acceptance Criteria

1. WHEN a PUT request is received at `/settings`, THE Router SHALL dispatch the request to the Settings_Endpoint save handler with the parsed request body and authenticated user ID.
2. WHEN a GET request is received at `/settings`, THE Router SHALL dispatch the request to the Settings_Endpoint retrieve handler with the authenticated user ID.
