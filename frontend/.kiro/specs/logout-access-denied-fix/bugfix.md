# Bugfix Requirements Document

## Introduction

The OAuth2 logout flow produces an "access denied" error when the user attempts to log out. This is a regression of a previously fixed issue. The `AuthService.logout()` method constructs the OAuth2 provider's logout URL with an `id_token_hint` query parameter. When the stored `_idToken` is `null` (e.g., after a token refresh that didn't return a new `id_token`, or if the token was lost), the method falls back to an empty string (`idToken ?? ''`). The OAuth2 provider at `oauth2.quran.foundation` rejects logout requests that include an empty `id_token_hint`, returning "access denied" instead of ending the session.

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN the user taps the logout button and `_idToken` is `null` in `AuthService`, THEN the system constructs a logout URL with `id_token_hint` set to an empty string, causing the OAuth2 provider to return "access denied".

1.2 WHEN the user taps the logout button and `_idToken` is an empty string in `AuthService`, THEN the system constructs a logout URL with `id_token_hint` set to an empty string, causing the OAuth2 provider to return "access denied".

1.3 WHEN the OAuth2 provider rejects the logout request with "access denied", THEN the system provides no error feedback to the user and the browser remains on the provider's error page, leaving the user stuck.

### Expected Behavior (Correct)

2.1 WHEN the user taps the logout button and `_idToken` is `null` in `AuthService`, THEN the system SHALL construct the logout URL without the `id_token_hint` parameter so the OAuth2 provider can process the logout without rejecting it.

2.2 WHEN the user taps the logout button and `_idToken` is an empty string in `AuthService`, THEN the system SHALL construct the logout URL without the `id_token_hint` parameter so the OAuth2 provider can process the logout without rejecting it.

2.3 WHEN the user taps the logout button and `_idToken` contains a valid token string, THEN the system SHALL include the `id_token_hint` parameter in the logout URL with the token value, enabling the provider to identify the session to terminate.

### Unchanged Behavior (Regression Prevention)

3.1 WHEN the user taps the logout button, THEN the system SHALL CONTINUE TO clear all stored tokens (`_accessToken`, `_idToken`, `_refreshToken`, `_tokenExpiry`) and the user profile from `AuthService` before constructing the logout URL.

3.2 WHEN the user taps the logout button, THEN the system SHALL CONTINUE TO include the `post_logout_redirect_uri` parameter in the logout URL pointing to the app root.

3.3 WHEN the user taps the logout button with a valid `_idToken`, THEN the system SHALL CONTINUE TO redirect the browser to the OAuth2 provider's logout endpoint at `{TOKEN_HOST}/oauth2/sessions/logout`.

3.4 WHEN logout completes and the provider redirects back, THEN the system SHALL CONTINUE TO display the Auth Screen so the user can re-authenticate.
