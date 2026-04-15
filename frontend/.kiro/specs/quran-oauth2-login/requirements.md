# Requirements Document

## Introduction

Replace the local credential-based authentication in the Quran Prep app with Quran.com's hosted OAuth2 login UI. The Auth_Screen's username/password form is commented out (not deleted) and replaced with a single "Continue with Quran.Foundation" button that opens the external OAuth2 authorization page. After the user authenticates on the hosted UI, the app handles the callback, exchanges the authorization code for tokens (access_token, id_token, refresh_token), decodes the JWT id_token for user profile information, and stores the tokens in Auth_Service. API calls switch from the current `Authorization: Bearer {username}` header to `x-auth-token` and `x-client-id` headers. The existing mock authentication code in Auth_Service, Auth_Screen, and the Env_File is commented out with explanatory comments rather than deleted, preserving it for reference.

## Glossary

- **Auth_Screen**: The login screen (`lib/screens/auth_screen.dart`) where users initiate authentication.
- **Entry_Screen**: The home screen (`lib/screens/entry_screen.dart`) where users configure and start a preparation session.
- **Auth_Service**: The Dart service class (`lib/services/auth_service.dart`) responsible for storing tokens, providing auth headers, and managing the OAuth2 session lifecycle.
- **Session_Service**: The Dart service class (`lib/services/session_service.dart`) that makes API calls using headers from Auth_Service.
- **Env_File**: The `.env` file at the project root that stores configuration values.
- **OAuth2_Provider**: The Quran.com OAuth2 authorization server at `https://oauth2.quran.foundation`.
- **Access_Token**: The OAuth2 access token used to authenticate API requests via the `x-auth-token` header.
- **Id_Token**: A JWT issued by OAuth2_Provider containing the authenticated user's profile claims (sub, name, email).
- **Refresh_Token**: A long-lived token used to obtain a new Access_Token without re-authentication.
- **Client_ID**: The OAuth2 client identifier stored in the Env_File and sent via the `x-client-id` header.
- **Client_Secret**: The OAuth2 client secret stored in the Env_File, used during the authorization code exchange.
- **State_Parameter**: A cryptographically random string used for CSRF protection during the OAuth2 authorization flow.
- **Authorization_Code**: A short-lived code returned by OAuth2_Provider after user consent, exchanged for tokens.
- **Callback_URI**: The redirect URI registered with OAuth2_Provider where the app receives the Authorization_Code.

## Requirements

### Requirement 1: OAuth2 Environment Configuration

**User Story:** As a developer, I want OAuth2 configuration stored in the `.env` file, so that client credentials and endpoints are configurable without code changes.

#### Acceptance Criteria

1. THE Env_File SHALL contain the following OAuth2 entries: `TOKEN_HOST`, `CLIENT_ID`, `CLIENT_SECRET`, `SCOPES`, and `SESSION_SECRET`.
2. THE Env_File SHALL set `TOKEN_HOST` to `https://oauth2.quran.foundation`.
3. THE Env_File SHALL set `SCOPES` to `openid offline_access profile email bookmark collection user`.
4. THE Env_File SHALL retain the existing mock credential entries (`LOGIN_USER_1`, `LOGIN_PASS_1`, `LOGIN_USER_2`, `LOGIN_PASS_2`, `LOGIN_USER_3`, `LOGIN_PASS_3`) as commented-out lines with a comment explaining they are replaced by OAuth2 authentication.
5. THE Auth_Service SHALL read `TOKEN_HOST`, `CLIENT_ID`, `CLIENT_SECRET`, `SCOPES`, and `SESSION_SECRET` from the Env_File at initialization time.

### Requirement 2: Comment Out Existing Mock Authentication Code

**User Story:** As a developer, I want the existing mock authentication code preserved as comments, so that it remains available for reference or rollback.

#### Acceptance Criteria

1. THE Auth_Service SHALL have the local credential validation method (`validate`) commented out with a comment stating it is replaced by OAuth2 authentication.
2. THE Auth_Service SHALL have the static `validUsers` list and `defaultUser` constant commented out with a comment stating they are replaced by OAuth2 authentication.
3. THE Auth_Screen SHALL have the username text field, password text field, visibility toggle, field-change listeners, and "Sign in" button logic commented out with a comment stating they are replaced by the OAuth2 login flow.
4. THE Auth_Screen SHALL have the "Forgot password?" link and "Sign up" hint row commented out with a comment stating they are replaced by the OAuth2 login flow.

### Requirement 3: OAuth2 Login Initiation

**User Story:** As a user, I want to tap a single button to authenticate via Quran.Foundation, so that I can log in without managing separate credentials.

#### Acceptance Criteria

1. THE Auth_Screen SHALL display a "Continue with Quran.Foundation" button.
2. WHEN the user taps the "Continue with Quran.Foundation" button, THE Auth_Service SHALL generate a cryptographically random State_Parameter for CSRF protection.
3. WHEN the user taps the "Continue with Quran.Foundation" button, THE Auth_Screen SHALL open the OAuth2_Provider authorization URL (`{TOKEN_HOST}/oauth2/auth`) in an external browser or web-auth popup, including query parameters: `client_id`, `redirect_uri` (the Callback_URI), `response_type=code`, `scope` (from Env_File SCOPES), and `state` (the generated State_Parameter).
4. WHILE the OAuth2 authorization flow is in progress, THE Auth_Screen SHALL display a loading indicator.
5. IF the user cancels the browser-based login or closes the popup, THEN THE Auth_Screen SHALL return to the idle state with the "Continue with Quran.Foundation" button enabled.

### Requirement 4: OAuth2 Callback and Token Exchange

**User Story:** As a user, I want the app to handle the OAuth2 callback automatically, so that I am logged in after authenticating on the Quran.Foundation page.

#### Acceptance Criteria

1. WHEN the OAuth2_Provider redirects to the Callback_URI with an Authorization_Code and a state parameter, THE Auth_Service SHALL verify that the returned state matches the previously generated State_Parameter.
2. IF the returned state does not match the stored State_Parameter, THEN THE Auth_Service SHALL reject the callback and THE Auth_Screen SHALL display an error message "Authentication failed: invalid state".
3. WHEN the state is valid, THE Auth_Service SHALL exchange the Authorization_Code for tokens by sending a POST request to `{TOKEN_HOST}/oauth2/token` with parameters: `grant_type=authorization_code`, `code`, `redirect_uri`, `client_id`, and `client_secret`.
4. WHEN the token exchange succeeds, THE Auth_Service SHALL store the Access_Token, Id_Token, Refresh_Token, and the token expiry time derived from `expires_in`.
5. IF the token exchange request fails, THEN THE Auth_Screen SHALL display an error message "Authentication failed: could not exchange code for tokens".

### Requirement 5: JWT Id_Token Decoding

**User Story:** As a developer, I want the id_token JWT decoded to extract user profile information, so that the app can identify the authenticated user.

#### Acceptance Criteria

1. WHEN the Auth_Service receives an Id_Token, THE Auth_Service SHALL decode the JWT payload without requiring a signing-key verification (the token is received directly from the OAuth2_Provider over HTTPS).
2. THE Auth_Service SHALL extract the `sub` (subject identifier), `name`, and `email` claims from the decoded Id_Token payload.
3. THE Auth_Service SHALL expose the decoded user profile (sub, name, email) via a getter so that other components can access the current user identity.

### Requirement 6: Updated Auth Headers for API Calls

**User Story:** As a developer, I want API calls to use the OAuth2 token headers, so that the backend can authenticate requests against the Quran.com identity system.

#### Acceptance Criteria

1. THE Auth_Service SHALL provide a method that returns a headers map containing `x-auth-token` set to the stored Access_Token and `x-client-id` set to the Client_ID from the Env_File.
2. THE Session_Service SHALL use the headers map from Auth_Service instead of the previous `Authorization: Bearer {username}` header for all API requests.
3. THE Auth_Service SHALL have the old `getAuthHeader()` method (which returned `Bearer {username}`) commented out with a comment stating it is replaced by OAuth2 token headers.

### Requirement 7: Token Refresh

**User Story:** As a user, I want my session to stay active without re-authenticating, so that I have an uninterrupted experience.

#### Acceptance Criteria

1. WHEN the stored Access_Token is expired or within 60 seconds of expiry, THE Auth_Service SHALL automatically request a new Access_Token by sending a POST request to `{TOKEN_HOST}/oauth2/token` with parameters: `grant_type=refresh_token`, `refresh_token`, `client_id`, and `client_secret`.
2. WHEN the token refresh succeeds, THE Auth_Service SHALL update the stored Access_Token, Id_Token (if returned), Refresh_Token (if rotated), and the token expiry time.
3. IF the token refresh fails, THEN THE Auth_Service SHALL clear all stored tokens and THE Auth_Screen SHALL be displayed so the user can re-authenticate.

### Requirement 8: OAuth2 Logout

**User Story:** As a user, I want to log out and have my session ended on both the app and the OAuth2 provider, so that my account is secure.

#### Acceptance Criteria

1. THE Entry_Screen SHALL display a logout control (icon or button) that initiates the logout flow.
2. WHEN the user taps the logout control, THE Auth_Service SHALL clear all stored tokens (Access_Token, Id_Token, Refresh_Token) and the user profile.
3. WHEN the user taps the logout control, THE Auth_Service SHALL open the OAuth2_Provider logout URL (`{TOKEN_HOST}/oauth2/sessions/logout`) with query parameters: `post_logout_redirect_uri` (the Callback_URI or app root) and `id_token_hint` (the stored Id_Token).
4. WHEN logout completes, THE app SHALL navigate to the Auth_Screen.

### Requirement 9: Auth Screen Visual Update

**User Story:** As a user, I want the login screen to clearly indicate I am signing in via Quran.Foundation, so that the experience feels trustworthy and cohesive.

#### Acceptance Criteria

1. THE Auth_Screen SHALL display a welcome heading and a subtitle consistent with the existing app design using AppColors and AppTextStyles.
2. THE Auth_Screen SHALL display the "Continue with Quran.Foundation" button styled with the app's primary color scheme.
3. WHEN an authentication error occurs, THE Auth_Screen SHALL display the error message in red text below the button.
4. THE Auth_Screen SHALL clear the error message when the user taps the "Continue with Quran.Foundation" button again.

### Requirement 10: Navigation and Auth_Service Passing

**User Story:** As a developer, I want the authenticated Auth_Service instance passed through the navigation flow, so that all screens have access to the OAuth2 tokens.

#### Acceptance Criteria

1. WHEN OAuth2 login succeeds, THE Auth_Screen SHALL navigate to the Entry_Screen passing the Auth_Service instance as a route argument.
2. THE Entry_Screen SHALL continue to receive the Auth_Service instance via route arguments and pass the Auth_Service instance to Session_Service.
3. THE Entry_Screen SHALL redirect to the Auth_Screen when route arguments are missing (preserving the existing refresh-safety behavior).
