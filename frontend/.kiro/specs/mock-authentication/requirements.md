# Requirements Document

## Introduction

Add a mock authentication system to the Quran Prep app. The system uses a simple Bearer token scheme with three predefined mock users (`demo-user-1`, `demo-user-2`, `demo-user-3`). The frontend allows the user to select a mock identity, stores the selection, and sends it as a Bearer token in the `Authorization` header of all API requests. The backend Lambda functions extract the user ID directly from the token value. This provides a lightweight simulation of real authentication without requiring an identity provider.

## Glossary

- **Mock_User**: One of three predefined user identities: `demo-user-1`, `demo-user-2`, or `demo-user-3`.
- **Auth_Token**: A Bearer token string whose value equals the selected Mock_User identifier (e.g., `demo-user-1`).
- **Auth_Service**: A Dart service class responsible for storing and providing the currently selected Mock_User identity.
- **User_Selector**: A UI widget on the Entry_Screen that allows the user to choose which Mock_User identity to use.
- **Auth_Header**: The HTTP `Authorization` header sent with API requests in the format `Bearer <Mock_User>`.
- **Token_Extractor**: Backend logic within Lambda functions that parses the Auth_Header to obtain the user ID.
- **Entry_Screen**: The home screen of the app (`lib/screens/entry_screen.dart`) where users configure their session.
- **Session_Service**: The existing Dart service class responsible for calling the session preparation API.

## Requirements

### Requirement 1: Mock User Selection

**User Story:** As a user, I want to select a mock user identity from the Entry Screen, so that my API requests are associated with a specific user.

#### Acceptance Criteria

1. THE User_Selector SHALL display the three Mock_User options: `demo-user-1`, `demo-user-2`, and `demo-user-3`.
2. WHEN the app launches, THE User_Selector SHALL have `demo-user-1` selected as the default Mock_User.
3. WHEN the user selects a Mock_User from the User_Selector, THE Auth_Service SHALL store the selected Mock_User identifier as the active identity.
4. THE User_Selector SHALL visually indicate which Mock_User is currently selected.

### Requirement 2: Auth Token Storage

**User Story:** As a developer, I want the selected mock user stored in a central service, so that all API services can access the current identity consistently.

#### Acceptance Criteria

1. THE Auth_Service SHALL store the currently selected Mock_User identifier in memory.
2. THE Auth_Service SHALL provide a method that returns the current Auth_Token in the format `Bearer <Mock_User>`.
3. WHEN no Mock_User has been explicitly selected, THE Auth_Service SHALL default to `demo-user-1`.

### Requirement 3: Frontend Authorization Header

**User Story:** As a developer, I want the Authorization header sent automatically with all API requests, so that the backend can identify the current user.

#### Acceptance Criteria

1. WHEN the Session_Service sends an API request, THE Session_Service SHALL include an `Authorization` header with the Auth_Token value from the Auth_Service.
2. THE Session_Service SHALL retrieve the Auth_Token from the Auth_Service for each request rather than using a hardcoded value.

### Requirement 4: Backend Token Extraction

**User Story:** As a developer, I want the Lambda functions to extract the user ID from the Authorization header, so that the backend can identify which mock user made the request.

#### Acceptance Criteria

1. WHEN a request contains an `Authorization` header with a Bearer token, THE Token_Extractor SHALL extract the user ID by removing the `Bearer ` prefix from the header value.
2. IF the `Authorization` header is missing from the request, THEN THE Token_Extractor SHALL return a 401 status code with a JSON body containing an error message indicating that authentication is required.
3. IF the `Authorization` header is present but the token value is not one of the three valid Mock_User identifiers, THEN THE Token_Extractor SHALL return a 403 status code with a JSON body containing an error message indicating an invalid user.
4. WHEN a valid user ID is extracted, THE Token_Extractor SHALL make the user ID available to the Lambda handler function for use in processing the request.

### Requirement 5: Valid Mock User Validation

**User Story:** As a developer, I want the set of valid mock users defined in a single place on the backend, so that validation is consistent and easy to update.

#### Acceptance Criteria

1. THE Token_Extractor SHALL validate the extracted user ID against a predefined list containing exactly `demo-user-1`, `demo-user-2`, and `demo-user-3`.
2. THE predefined list of valid Mock_User identifiers SHALL be defined as a constant in a shared utility module accessible to all Lambda functions.

### Requirement 6: Visual Consistency

**User Story:** As a user, I want the user selector to match the existing app design, so that the experience feels cohesive.

#### Acceptance Criteria

1. THE User_Selector SHALL be placed on the Entry_Screen above the existing input fields.
2. THE User_Selector SHALL use styling consistent with the existing Entry_Screen design (matching font sizes, colors from AppColors, and spacing conventions).
