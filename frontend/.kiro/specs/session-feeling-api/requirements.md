# Requirements Document

## Introduction

After completing a recitation session, the user selects how the session felt on the feedback screen. Currently the feedback screen is purely cosmetic — it shows a selection UI and animates to the home screen without persisting the user's choice. This feature connects the feedback screen to the backend by calling `PATCH /sessions/{sessionId}/feeling` with the selected feeling value, so the backend can tailor future session preparation.

## Glossary

- **Feedback_Screen**: The post-recitation screen (`FeedbackScreen` widget) where the user selects how the session felt
- **Session_Service**: The service class (`SessionService`) responsible for all session-related API calls
- **Feeling_Value**: One of three valid string values representing the user's session feedback: `smooth`, `struggled`, `revisit`
- **Session_ID**: A unique string identifier returned by the backend when a session is created via `POST /sessions`, stored in `SessionResponse.sessionId`
- **API_Key**: The `x-api-key` header value loaded from the `.env` file, required for all backend requests
- **Auth_Header**: The `Authorization` header value obtained from `AuthService.getAuthHeader()`

## Requirements

### Requirement 1: Pass Session ID to Feedback Screen

**User Story:** As a user, I want the feedback screen to know which session I just completed, so that my feeling can be recorded against the correct session.

#### Acceptance Criteria

1. WHEN the Recitation_Screen navigates to the Feedback_Screen, THE Recitation_Screen SHALL pass the Session_ID as a navigation argument
2. WHEN the Feedback_Screen is opened, THE Feedback_Screen SHALL extract the Session_ID from the navigation arguments
3. IF the Session_ID is missing from the navigation arguments, THEN THE Feedback_Screen SHALL still display the feeling options and navigate home on selection without calling the API

### Requirement 2: Submit Feeling API Method

**User Story:** As a developer, I want a method in the Session_Service to submit a feeling for a session, so that the API call is encapsulated alongside other session operations.

#### Acceptance Criteria

1. THE Session_Service SHALL expose a `submitFeeling` method that accepts a Session_ID and a Feeling_Value
2. WHEN `submitFeeling` is called, THE Session_Service SHALL send a PATCH request to `{BASE_URL}/sessions/{sessionId}/feeling` with a JSON body containing the feeling field
3. WHEN `submitFeeling` is called, THE Session_Service SHALL include the `Content-Type`, `Authorization`, and `x-api-key` headers consistent with existing Session_Service methods
4. THE Session_Service SHALL accept only the Feeling_Value values `smooth`, `struggled`, or `revisit`
5. IF the API responds with a non-200 status code, THEN THE Session_Service SHALL throw an exception containing the status code

### Requirement 3: Map UI Selection to Feeling Value

**User Story:** As a user, I want my tap on a feedback option to map to the correct feeling value, so that the backend receives an accurate representation of my choice.

#### Acceptance Criteria

1. WHEN the user selects "Smooth", THE Feedback_Screen SHALL map the selection to the Feeling_Value `smooth`
2. WHEN the user selects "Struggled a little", THE Feedback_Screen SHALL map the selection to the Feeling_Value `struggled`
3. WHEN the user selects "Need to revisit", THE Feedback_Screen SHALL map the selection to the Feeling_Value `revisit`

### Requirement 4: Call Submit Feeling on Selection

**User Story:** As a user, I want my feeling choice to be sent to the backend when I tap an option, so that my feedback is persisted.

#### Acceptance Criteria

1. WHEN the user selects a feeling option and a valid Session_ID is available, THE Feedback_Screen SHALL call `submitFeeling` on the Session_Service with the Session_ID and the mapped Feeling_Value
2. WHEN the `submitFeeling` call succeeds, THE Feedback_Screen SHALL show the "Session complete." animation and navigate to the home screen
3. IF the `submitFeeling` call fails, THEN THE Feedback_Screen SHALL still show the "Session complete." animation and navigate to the home screen without blocking the user

### Requirement 5: Pass Session Service to Feedback Screen

**User Story:** As a developer, I want the Feedback_Screen to receive the Session_Service instance, so that it can make the API call without creating its own service instance.

#### Acceptance Criteria

1. WHEN the Recitation_Screen navigates to the Feedback_Screen, THE Recitation_Screen SHALL pass the Session_Service instance as a navigation argument
2. WHEN the Feedback_Screen is opened, THE Feedback_Screen SHALL extract the Session_Service from the navigation arguments
3. IF the Session_Service is missing from the navigation arguments, THEN THE Feedback_Screen SHALL skip the API call and proceed with the existing animation and navigation behavior
