# Requirements Document

## Introduction

This document defines the requirements for moving the OAuth2 token exchange proxy from a local Dart server into the existing AWS Lambda function. The Flutter web app currently calls a local proxy at `localhost:5001/oauth2/token` to exchange authorization codes for tokens, avoiding CORS issues when communicating with the Quran.com OAuth2 token endpoint. This feature adds a `/oauth2/token` route to the Lambda so the Flutter app can call the deployed API Gateway endpoint instead of a local proxy.

The proxy accepts a form-urlencoded POST body containing OAuth2 token exchange parameters, extracts `client_id` and `client_secret` from the body, converts them to a Basic Auth header, removes them from the forwarded body, and forwards the cleaned request to the upstream Quran.com OAuth2 token endpoint. The upstream response is returned to the caller as-is.

The route must bypass the existing Bearer token authentication since it is used to obtain a token in the first place. The upstream token host must be determined by the `QF_ENV` environment variable to support both production and pre-live environments. Client credentials are sent by the Flutter app in the request body and must be forwarded to the upstream endpoint — the Lambda does not inject its own stored credentials.

## Glossary

- **Token_Proxy**: The new Lambda route handler module responsible for proxying OAuth2 token exchange requests to the upstream token endpoint
- **Upstream_Token_Endpoint**: The Quran.com OAuth2 token endpoint that the Token_Proxy forwards requests to. For production: `https://oauth2.quran.com/oauth2/token`. For pre-live: `https://prelive-oauth2.quran.foundation/oauth2/token`
- **Router**: The existing `routeRequest` function in `src/router.mjs` that dispatches requests by HTTP method and path
- **Handler**: The existing Lambda entry point in `src/index.mjs` that extracts the user ID from the Bearer token and delegates to the Router
- **QF_ENV**: Environment variable that controls which Quran.com environment to target (`production` or `prelive`)
- **TOKEN_HOST**: The base URL of the OAuth2 token server, derived from QF_ENV at runtime. Production: `https://oauth2.quran.com`. Pre-live: `https://prelive-oauth2.quran.foundation`
- **Basic_Auth_Header**: A Base64-encoded `client_id:client_secret` string sent as the `Authorization: Basic` header to the Upstream_Token_Endpoint
- **Form_Body**: The `application/x-www-form-urlencoded` request body containing OAuth2 token exchange parameters such as `grant_type`, `code`, `redirect_uri`, `client_id`, and `client_secret`
- **Session_Sync**: The `syncReadingSession` function in `src/sessions.mjs` that posts completed reading session data to the Reading_Sessions_API
- **Reading_Sessions_API**: The Quran.com Reading Sessions endpoint at `https://apis-prelive.quran.foundation/auth/v1/reading-sessions` that records user reading activity
- **User_Access_Token**: The OAuth2 access token belonging to the authenticated user, received as the Bearer token in the incoming request's Authorization header
- **QF_PRELIVE_CLIENT_ID**: Environment variable containing the Quran Foundation pre-live OAuth2 client ID, used as the `x-client-id` header when calling the Reading_Sessions_API

## Requirements

### Requirement 1: Route Registration Without Authentication

**User Story:** As a Flutter app developer, I want the `/oauth2/token` endpoint to be accessible without a Bearer token, so that I can exchange an authorization code for an access token before I have one.

#### Acceptance Criteria

1. WHEN a POST request is received with path `/oauth2/token`, THE Handler SHALL route the request to the Token_Proxy without requiring a Bearer token in the Authorization header
2. WHEN a non-POST request is received with path `/oauth2/token`, THE Router SHALL return HTTP status 405 with an error body `{ "error": "Method Not Allowed" }`
3. THE Handler SHALL continue to require Bearer token authentication for all routes other than `/oauth2/token`

### Requirement 2: Request Parsing and Credential Extraction

**User Story:** As a Flutter app developer, I want the proxy to accept my form-urlencoded token request and handle credential formatting, so that the upstream endpoint receives properly formatted Basic Auth credentials.

#### Acceptance Criteria

1. WHEN the Token_Proxy receives a POST request, THE Token_Proxy SHALL parse the Form_Body as `application/x-www-form-urlencoded`
2. THE Token_Proxy SHALL extract the `client_id` and `client_secret` values from the parsed Form_Body
3. THE Token_Proxy SHALL construct a Basic_Auth_Header by Base64-encoding the string `{client_id}:{client_secret}`
4. THE Token_Proxy SHALL remove the `client_id` and `client_secret` fields from the Form_Body before forwarding
5. IF the Form_Body is missing or empty, THEN THE Token_Proxy SHALL return HTTP status 400 with body `{ "error": "bad_request", "message": "Missing request body" }`
6. IF the Form_Body does not contain a `client_id` field, THEN THE Token_Proxy SHALL return HTTP status 400 with body `{ "error": "bad_request", "message": "Missing client_id" }`
7. IF the Form_Body does not contain a `client_secret` field, THEN THE Token_Proxy SHALL return HTTP status 400 with body `{ "error": "bad_request", "message": "Missing client_secret" }`

### Requirement 3: Upstream Request Forwarding

**User Story:** As a Flutter app developer, I want the proxy to forward my token request to the correct Quran.com OAuth2 endpoint, so that I receive a valid access token.

#### Acceptance Criteria

1. THE Token_Proxy SHALL forward the cleaned Form_Body as a POST request to the Upstream_Token_Endpoint with `Content-Type: application/x-www-form-urlencoded`
2. THE Token_Proxy SHALL include the Basic_Auth_Header as the `Authorization` header in the forwarded request
3. THE Token_Proxy SHALL NOT include any fields other than the cleaned Form_Body parameters in the forwarded request body
4. WHEN QF_ENV is set to `production`, THE Token_Proxy SHALL use `https://oauth2.quran.com` as the TOKEN_HOST
5. WHEN QF_ENV is set to `prelive`, THE Token_Proxy SHALL use `https://prelive-oauth2.quran.foundation` as the TOKEN_HOST
6. IF QF_ENV is not set or has an unrecognized value, THEN THE Token_Proxy SHALL default to the production TOKEN_HOST `https://oauth2.quran.com`

### Requirement 4: Response Handling

**User Story:** As a Flutter app developer, I want to receive the upstream token response as-is, so that my app can process the OAuth2 tokens without any transformation.

#### Acceptance Criteria

1. WHEN the Upstream_Token_Endpoint returns a response, THE Token_Proxy SHALL return the upstream HTTP status code to the caller
2. WHEN the Upstream_Token_Endpoint returns a response, THE Token_Proxy SHALL return the upstream response body to the caller with `Content-Type: application/json`
3. THE Token_Proxy SHALL NOT modify, filter, or transform the upstream response body

### Requirement 5: Error Handling

**User Story:** As a Flutter app developer, I want clear error responses when the proxy fails, so that I can diagnose issues in my app.

#### Acceptance Criteria

1. IF the upstream request fails due to a network error, timeout, or DNS resolution failure, THEN THE Token_Proxy SHALL return HTTP status 502 with body `{ "error": "proxy_error", "message": "<error description>" }`
2. IF an unexpected error occurs during request processing, THEN THE Token_Proxy SHALL return HTTP status 502 with body `{ "error": "proxy_error", "message": "<error description>" }`
3. THE Token_Proxy SHALL log all errors with sufficient detail for debugging, including the error message and stack trace

### Requirement 6: Security Constraints

**User Story:** As a backend developer, I want the proxy to only forward requests to known Quran.com OAuth2 endpoints, so that the Lambda cannot be used as an open proxy.

#### Acceptance Criteria

1. THE Token_Proxy SHALL only forward requests to the Upstream_Token_Endpoint derived from the QF_ENV environment variable
2. THE Token_Proxy SHALL NOT accept a target URL or host from the request body, query parameters, or headers
3. THE Token_Proxy SHALL NOT log or expose the `client_secret` value or the Basic_Auth_Header value in any log output
4. THE Token_Proxy SHALL NOT store or cache any credentials from the request

### Requirement 7: Environment Configuration

**User Story:** As a backend developer, I want the token host to be derived from the existing QF_ENV variable, so that no additional environment configuration is needed for deployment.

#### Acceptance Criteria

1. THE Token_Proxy SHALL derive the TOKEN_HOST from the QF_ENV environment variable at request time, not at module load time
2. THE Token_Proxy SHALL NOT require any new environment variables beyond the existing QF_ENV
3. THE Token_Proxy SHALL NOT read from `.env` files or any file-based configuration

### Requirement 8: Forward User Token for Reading Session Sync

**User Story:** As a Flutter app user, I want my own OAuth access token to be forwarded when syncing reading sessions, so that the Reading Sessions API records activity under my account instead of a server-side service account.

#### Acceptance Criteria

1. WHEN the Session_Sync sends a request to the Reading_Sessions_API, THE Session_Sync SHALL use the User_Access_Token as the `x-auth-token` header value instead of a server-side client credentials token
2. WHEN the Session_Sync sends a request to the Reading_Sessions_API, THE Session_Sync SHALL include the QF_PRELIVE_CLIENT_ID environment variable value as the `x-client-id` header
3. THE Session_Sync SHALL extract the User_Access_Token from the incoming request's Authorization header by removing the `Bearer ` prefix
4. THE Session_Sync SHALL accept the User_Access_Token as a parameter passed from the calling function rather than fetching a new token via client credentials flow
5. THE Session_Sync SHALL NOT call `getPreliveAccessToken()` or any client credentials token endpoint when syncing reading sessions
6. IF the User_Access_Token is missing or empty, THEN THE Session_Sync SHALL skip the reading session sync and log a warning
7. THE Session_Sync SHALL NOT log or expose the User_Access_Token value in any log output
