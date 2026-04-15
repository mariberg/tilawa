# Implementation Plan: OAuth Token Proxy

## Overview

Add a `/oauth2/token` POST route that proxies OAuth2 token exchange requests to the Quran.com OAuth2 endpoint, bypassing Bearer token auth. Also modify `syncReadingSession()` to use the caller's Bearer token instead of server-side client credentials. New module `src/tokenProxy.mjs` handles the proxy logic. Existing files `src/index.mjs`, `src/router.mjs`, and `src/sessions.mjs` are modified for auth bypass, token threading, and sync changes.

## Tasks

- [x] 1. Implement token proxy module
  - [x] 1.1 Create `src/tokenProxy.mjs` with `getTokenHost()` and `handleTokenProxy()`
    - Implement `getTokenHost()`: returns `https://prelive-oauth2.quran.foundation` when `QF_ENV === "prelive"`, otherwise `https://oauth2.quran.com`
    - Implement `handleTokenProxy(event)`:
      - Validate method is POST → return 405 `{ "error": "Method Not Allowed" }` if not
      - Validate body is present → return 400 `{ "error": "bad_request", "message": "Missing request body" }` if missing/empty
      - Parse form body as `application/x-www-form-urlencoded`
      - Extract `client_id` → return 400 if missing
      - Extract `client_secret` → return 400 if missing
      - Build Basic Auth header: `Basic ${Buffer.from(client_id + ":" + client_secret).toString("base64")}`
      - Remove `client_id` and `client_secret` from params
      - POST to `${getTokenHost()}/oauth2/token` with cleaned body and Basic Auth
      - Return upstream status code and JSON body as-is
      - On fetch error → return 502 `{ "error": "proxy_error", "message": error.message }`
      - Log errors with detail but never log client_secret or Basic Auth header value
    - Export `handleTokenProxy` and `getTokenHost`
    - _Requirements: 1.2, 2.1–2.7, 3.1–3.6, 4.1–4.3, 5.1–5.3, 6.1–6.4, 7.1_

  - [x] 1.2 Modify `src/index.mjs` to bypass auth for `/oauth2/token`
    - Before calling `extractUserId()`, check if `event.path === "/oauth2/token"`
    - If matched, call `handleTokenProxy(event)` and return result with CORS headers
    - For all other paths, continue existing auth flow
    - Also extract `userAccessToken` from the Authorization header (after "Bearer " prefix) and pass to `routeRequest()`
    - _Requirements: 1.1, 1.3, 8.3_

  - [x] 1.3 Modify `src/router.mjs` to accept and pass `userAccessToken`
    - Update `routeRequest(event, userId, userAccessToken)` signature
    - Pass `userAccessToken` to `createSession()` call
    - _Requirements: 8.3, 8.4_

- [x] 2. Modify session sync to use user token
  - [x] 2.1 Update `syncReadingSession()` in `src/sessions.mjs` to accept `userAccessToken` parameter
    - Change signature to `syncReadingSession(chapterNumber, verseNumber, userAccessToken)`
    - If `userAccessToken` is missing/empty, log a warning and return early (skip sync)
    - Use `userAccessToken` as `x-auth-token` header instead of calling `getPreliveAccessToken()`
    - Use `process.env.QF_PRELIVE_CLIENT_ID` as `x-client-id` header (instead of `QF_CLIENT_ID`)
    - Do NOT log the `userAccessToken` value
    - _Requirements: 8.1, 8.2, 8.4, 8.5, 8.6, 8.7_

  - [x] 2.2 Update `createSession()` in `src/sessions.mjs` to accept and pass `userAccessToken`
    - Change signature to `createSession(body, userId, userAccessToken)`
    - Pass `userAccessToken` to `syncReadingSession()`
    - _Requirements: 8.3, 8.4_

- [ ] 3. Write property tests
  - [ ]* 3.1 Write property test: Non-POST methods return 405 (Property 1)
    - Generate random HTTP methods excluding POST; verify 405 response with `{ "error": "Method Not Allowed" }`
    - File: `tests/property/oauth-token-proxy.property.test.mjs`
    - **Validates: Requirements 1.2**

  - [ ]* 3.2 Write property test: Basic Auth encoding correctness (Property 2)
    - Generate random `client_id` and `client_secret` strings; build form body; mock fetch; verify Authorization header is `Basic base64(id:secret)`
    - File: `tests/property/oauth-token-proxy.property.test.mjs`
    - **Validates: Requirements 2.2, 2.3, 3.2**

  - [ ]* 3.3 Write property test: Forwarded body excludes credentials (Property 3)
    - Generate random form bodies with `client_id`, `client_secret`, and additional fields; mock fetch; verify forwarded body has all fields except credentials
    - File: `tests/property/oauth-token-proxy.property.test.mjs`
    - **Validates: Requirements 2.4, 3.1, 3.3**

  - [ ]* 3.4 Write property test: TOKEN_HOST resolution from QF_ENV (Property 4)
    - Generate random QF_ENV values; verify `getTokenHost()` returns correct URL; verify changing QF_ENV between calls changes result
    - File: `tests/property/oauth-token-proxy.property.test.mjs`
    - **Validates: Requirements 3.4, 3.5, 3.6, 6.1, 7.1**

  - [ ]* 3.5 Write property test: Upstream response pass-through (Property 5)
    - Generate random HTTP status codes and JSON objects; mock fetch; verify proxy returns same status and body
    - File: `tests/property/oauth-token-proxy.property.test.mjs`
    - **Validates: Requirements 4.1, 4.2, 4.3**

  - [ ]* 3.6 Write property test: Fetch errors produce 502 (Property 6)
    - Generate random Error objects; mock fetch to throw; verify 502 response with `proxy_error`
    - File: `tests/property/oauth-token-proxy.property.test.mjs`
    - **Validates: Requirements 5.1, 5.2**

  - [ ]* 3.7 Write property test: User token forwarded as x-auth-token (Property 7)
    - Generate random non-empty token strings; mock fetch in syncReadingSession; verify `x-auth-token` header matches
    - File: `tests/property/oauth-token-proxy.property.test.mjs`
    - **Validates: Requirements 8.1, 8.3**

  - [ ]* 3.8 Write property test: Missing user token skips sync (Property 8)
    - Generate null, undefined, and empty string tokens; verify no fetch call and warning logged
    - File: `tests/property/oauth-token-proxy.property.test.mjs`
    - **Validates: Requirements 8.6**

- [ ] 4. Write unit tests
  - [ ]* 4.1 Write unit tests for token proxy and session sync changes
    - Handler routes POST `/oauth2/token` to token proxy without auth (Req 1.1)
    - Handler still requires auth for other paths (Req 1.3)
    - Missing body returns 400 "Missing request body" (Req 2.5)
    - Body without `client_id` returns 400 "Missing client_id" (Req 2.6)
    - Body without `client_secret` returns 400 "Missing client_secret" (Req 2.7)
    - Error logging includes error message but not secrets (Req 5.3, 6.3)
    - `syncReadingSession` uses `QF_PRELIVE_CLIENT_ID` as `x-client-id` (Req 8.2)
    - `syncReadingSession` does not call `getPreliveAccessToken()` (Req 8.5)
    - File: `tests/unit/oauth-token-proxy.test.mjs`

- [x] 5. Final checkpoint
  - Verify all tests pass with `vitest --run`
  - Ensure no secrets are hardcoded or logged
  - Confirm existing routes still work with auth

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- New file: `src/tokenProxy.mjs` (token proxy logic)
- Modified files: `src/index.mjs`, `src/router.mjs`, `src/sessions.mjs`
- Test files: `tests/property/oauth-token-proxy.property.test.mjs`, `tests/unit/oauth-token-proxy.test.mjs`
- No new environment variables needed — uses existing `QF_ENV` and `QF_PRELIVE_CLIENT_ID`
- No infrastructure changes to `template.yaml`
- Property tests use `fast-check` with `vitest` (both already in devDependencies)
- All credentials come from `process.env` — no hardcoded secrets
