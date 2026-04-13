# Requirements Document

## Introduction

Replace the mock user-selector authentication in the Quran Prep app with a proper login screen. Users enter a username and password on the Auth Screen, and the app validates the credentials locally against values stored in the `.env` file. On successful login, the Auth_Service is configured with the authenticated user and the app navigates to the Entry Screen. The User_Selector widget is removed from the Entry Screen since user identity is now established at login time.

## Glossary

- **Auth_Screen**: The login screen (`lib/screens/auth_screen.dart`) where users enter their username and password.
- **Entry_Screen**: The home screen (`lib/screens/entry_screen.dart`) where users configure and start a preparation session.
- **Auth_Service**: The Dart service class (`lib/services/auth_service.dart`) responsible for storing the current user identity and providing the authorization header.
- **Env_File**: The `.env` file at the project root that stores configuration values including login credentials.
- **Login_Credentials**: A username and password pair stored in the Env_File for a specific demo user.
- **User_Selector**: The pill-shaped widget (`lib/widgets/user_selector.dart`) currently used on the Entry Screen to pick a mock user identity.

## Requirements

### Requirement 1: Store Login Credentials in Environment File

**User Story:** As a developer, I want login credentials stored in the `.env` file, so that credentials are configurable without code changes.

#### Acceptance Criteria

1. THE Env_File SHALL contain a username entry and a password entry for each of the three demo users: `demo-user-1`, `demo-user-2`, and `demo-user-3`.
2. THE Env_File SHALL store the following Login_Credentials:
   - `demo-user-1` with password `test`
   - `demo-user-2` with password `Password1234#`
   - `demo-user-3` with password `Password1234#`
3. THE Auth_Service SHALL read Login_Credentials from the Env_File at validation time rather than using hardcoded values.

### Requirement 2: Login Screen Credential Entry

**User Story:** As a user, I want to enter my username and password on the Auth Screen, so that I can authenticate and access the app.

#### Acceptance Criteria

1. THE Auth_Screen SHALL display a text input field labeled "USERNAME" for entering the username.
2. THE Auth_Screen SHALL display a text input field labeled "PASSWORD" for entering the password.
3. THE Auth_Screen SHALL obscure the password input by default.
4. WHEN the user taps the visibility toggle on the password field, THE Auth_Screen SHALL toggle between obscured and visible password text.
5. THE Auth_Screen SHALL display a "Sign in" button that initiates credential validation.
6. WHILE the username field or the password field is empty, THE Auth_Screen SHALL disable the "Sign in" button.

### Requirement 3: Local Credential Validation

**User Story:** As a user, I want my credentials validated when I sign in, so that only authorized users can access the app.

#### Acceptance Criteria

1. WHEN the user taps "Sign in", THE Auth_Screen SHALL compare the entered username and password against all Login_Credentials loaded from the Env_File.
2. WHEN the entered username and password match a Login_Credentials entry, THE Auth_Service SHALL store the matched username as the current user identity.
3. WHEN the entered username and password match a Login_Credentials entry, THE Auth_Screen SHALL navigate to the Entry_Screen.
4. IF the entered username and password do not match any Login_Credentials entry, THEN THE Auth_Screen SHALL display an error message "Invalid username or password".
5. THE Auth_Screen SHALL clear the error message when the user modifies the username or password field after a failed attempt.

### Requirement 4: Auth Service Integration After Login

**User Story:** As a developer, I want the Auth Service configured with the logged-in user after successful authentication, so that all subsequent API requests use the correct identity.

#### Acceptance Criteria

1. WHEN login succeeds, THE Auth_Service SHALL have the authenticated user set via `setUser` before navigation to the Entry_Screen occurs.
2. THE Entry_Screen SHALL receive the Auth_Service instance with the authenticated user already set.
3. THE Session_Service SHALL continue to retrieve the authorization header from the Auth_Service for each API request.

### Requirement 5: Remove User Selector from Entry Screen

**User Story:** As a developer, I want the User Selector removed from the Entry Screen, so that user identity is established only through the login flow.

#### Acceptance Criteria

1. THE Entry_Screen SHALL NOT display the User_Selector widget.
2. THE Entry_Screen SHALL NOT display the "MOCK USER" label.
3. THE Entry_Screen SHALL continue to function with the Auth_Service user identity that was set during login.

### Requirement 6: Login Screen Visual Consistency

**User Story:** As a user, I want the login screen to match the existing app design, so that the experience feels cohesive.

#### Acceptance Criteria

1. THE Auth_Screen SHALL use colors from AppColors and text styles from AppTextStyles consistent with the rest of the app.
2. THE Auth_Screen SHALL display a welcome heading and a subtitle above the input fields.
3. THE Auth_Screen SHALL display the error message in red text below the input fields when validation fails.
