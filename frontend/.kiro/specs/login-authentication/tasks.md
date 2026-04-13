# Implementation Plan: Login Authentication

## Overview

Replace the mock `UserSelectorWidget` authentication with a proper login flow. Add credentials to `.env`, add a `validate()` method to `AuthService`, wire up `AuthScreen` with form controllers and validation logic, update routing to pass `AuthService` via route arguments, and remove the user selector from `EntryScreen`.

## Tasks

- [x] 1. Add login credentials to `.env` and update `AuthService`
  - [x] 1.1 Add credential entries to `.env`
    - Add `LOGIN_USER_1=demo-user-1`, `LOGIN_PASS_1=test`, `LOGIN_USER_2=demo-user-2`, `LOGIN_PASS_2=Password1234#`, `LOGIN_USER_3=demo-user-3`, `LOGIN_PASS_3=Password1234#` to the `.env` file
    - _Requirements: 1.1, 1.2_

  - [x] 1.2 Add `validate()` method to `AuthService`
    - Import `flutter_dotenv` in `lib/services/auth_service.dart`
    - Add `bool validate(String username, String password)` method that loops through `LOGIN_USER_N` / `LOGIN_PASS_N` (N=1..3) from `dotenv.env` and returns `true` on exact match, `false` otherwise
    - _Requirements: 1.3, 3.1_

  - [ ]* 1.3 Write property test for credential validation (Property 2)
    - **Property 2: Credential validation correctness**
    - Generate random username/password pairs (including the three known pairs) and verify `validate()` returns `true` if and only if the pair matches a `.env` credential entry
    - **Validates: Requirements 3.1, 3.4**

- [x] 2. Wire up `AuthScreen` with login form logic
  - [x] 2.1 Add `TextEditingController`s and state to `AuthScreen`
    - Add `_usernameController` and `_passwordController` `TextEditingController` instances
    - Add `_errorMessage` nullable `String` state variable
    - Add `_isButtonEnabled` boolean state derived from both controllers being non-empty
    - Attach listeners to both controllers that update `_isButtonEnabled` and clear `_errorMessage` on text change
    - Dispose controllers in `dispose()`
    - _Requirements: 2.1, 2.2, 2.5, 2.6, 3.5_

  - [x] 2.2 Connect controllers to text fields and implement sign-in logic
    - Assign `_usernameController` to the USERNAME `TextField` and `_passwordController` to the PASSWORD `TextField`
    - Create an `AuthService` instance in `_AuthScreenState`
    - On "Sign in" tap: call `_authService.validate(username, password)`. On success, call `_authService.setUser(username)` and `Navigator.pushReplacementNamed(context, '/home', arguments: _authService)`. On failure, set `_errorMessage` to `"Invalid username or password"`
    - Disable the "Sign in" button (`onPressed: null`) when `_isButtonEnabled` is false
    - _Requirements: 2.5, 2.6, 3.1, 3.2, 3.3, 3.4, 4.1_

  - [x] 2.3 Display error message below input fields
    - When `_errorMessage` is non-null, render a `Text` widget in red below the password field showing the error message
    - _Requirements: 3.4, 6.3_

  - [ ]* 2.4 Write property test for sign-in button enabled state (Property 1)
    - **Property 1: Sign-in button enabled state tracks field emptiness**
    - Generate random string pairs for username and password (including empty strings). For each pair, set the text controllers and verify the button's `onPressed` is non-null iff both strings are non-empty
    - **Validates: Requirements 2.6**

- [x] 3. Checkpoint
  - Ensure all tests pass, ask the user if questions arise.

- [x] 4. Update `EntryScreen` and routing
  - [x] 4.1 Update `EntryScreen` to accept `AuthService` via constructor or route arguments
    - Remove the `UserSelectorWidget` import and usage from `lib/screens/entry_screen.dart`
    - Remove the "MOCK USER" label and `UserSelectorWidget` widget from the `build` method
    - Remove the local `final AuthService _authService = AuthService();` instantiation
    - Extract `AuthService` from `ModalRoute.of(context)!.settings.arguments` in `didChangeDependencies` or `build`, and use it for `SessionService`
    - _Requirements: 4.2, 5.1, 5.2, 5.3_

  - [x] 4.2 Update routing in `main.dart`
    - Change the `/home` route from `const EntryScreen()` to extract `AuthService` from route arguments and pass it to `EntryScreen`
    - Use `onGenerateRoute` or keep named routes with argument extraction in `EntryScreen`
    - _Requirements: 4.1, 4.2_

  - [ ]* 4.3 Write unit tests for `EntryScreen` changes
    - Verify `UserSelectorWidget` and "MOCK USER" label are absent from `EntryScreen`
    - Verify `EntryScreen` receives `AuthService` with user already set and passes it to `SessionService`
    - _Requirements: 5.1, 5.2, 5.3, 4.2, 4.3_

- [x] 5. Clean up `UserSelectorWidget`
  - [x] 5.1 Remove or deprecate `lib/widgets/user_selector.dart`
    - Delete the file or leave it unused; ensure no remaining imports reference it
    - _Requirements: 5.1_

- [x] 6. Final checkpoint
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Property tests use loop-based random generation inside standard `test()` blocks (Dart's PBT ecosystem is limited)
- `AuthService` is passed from `AuthScreen` to `EntryScreen` via route arguments to avoid introducing a state management library
