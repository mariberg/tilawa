# Implementation Plan: Arabic Level Selection

## Overview

Add an Arabic level selection flow gated on first login. Create `LevelService` for API calls, `LevelScreen` for initial selection, `SettingsScreen` for changing the level, a shared `LevelOptionPicker` widget, and wire navigation in `AuthScreen`, `EntryScreen`, and `main.dart`.

## Tasks

- [ ] 1. Create LevelService
  - [x] 1.1 Create `lib/services/level_service.dart`
    - Create `LevelService` class accepting `AuthService` in constructor
    - Add `String? _currentLevel` field and `currentLevel` getter
    - Implement `fetchLevel({http.Client? client})` — GET `{BASE_URL}/users/level` with auth headers and `x-api-key`, parse response JSON, store level in `_currentLevel`, return it. On failure, return null.
    - Implement `saveLevel(String level, {http.Client? client})` — validate level is one of `beginner`, `intermediate`, `advanced` (throw `ArgumentError` otherwise). PUT `{BASE_URL}/users/level` with JSON body `{"level": level}`, auth headers, and `x-api-key`. On success, update `_currentLevel`. On failure, throw.
    - Follow `SessionService` patterns: read `BASE_URL`/`API_KEY` from `dotenv.env`, use `getAuthHeaders()`, accept optional `http.Client`
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 3.1, 3.2, 3.4, 4.1, 4.2, 4.3, 4.4_

  - [ ]* 1.2 Write property test for fetch level caches result (Property 4)
    - **Property 4: Fetch level caches result locally**
    - Generate random valid level strings and null. Mock API responses. Call `fetchLevel()` and verify `currentLevel` matches.
    - **Validates: Requirements 4.2, 4.3**

  - [ ]* 1.3 Write property test for save level updates cache (Property 5)
    - **Property 5: Save level updates local cache**
    - For each valid level, mock successful API response. Call `saveLevel()` and verify `currentLevel` equals saved value.
    - **Validates: Requirements 3.2, 6.4**

  - [ ]* 1.4 Write property test for save-fetch round trip (Property 3)
    - **Property 3: Save-fetch level round trip**
    - For each valid level, mock backend to echo saved value. Call `saveLevel()` then `fetchLevel()` and verify returned value matches.
    - **Validates: Requirements 3.1, 3.2, 4.2**

- [ ] 2. Create shared LevelOptionPicker widget
  - [x] 2.1 Create `lib/widgets/level_option_picker.dart`
    - Create `LevelOptionPicker` stateless widget with `selectedLevel` (`String?`) and `onSelected` (`ValueChanged<String>`) parameters
    - Render three tappable cards with labels "I'm a beginner", "I can follow along", "I read with understanding" mapping to `beginner`, `intermediate`, `advanced`
    - Highlight selected card with `AppColors.primary` border and `AppColors.primaryLight` background; unselected cards use `AppColors.border`
    - Use `AppTextStyles.body` for labels
    - _Requirements: 1.2, 1.3, 1.4, 6.1_

- [ ] 3. Create LevelScreen
  - [x] 3.1 Create `lib/screens/level_screen.dart`
    - Create `LevelScreen` stateful widget
    - Extract `AuthService` and `LevelService` from route arguments in `didChangeDependencies`; redirect to `/` if missing
    - Display heading "What's your Arabic level?" using `AppTextStyles.h1`
    - Use `LevelOptionPicker` for the three options
    - Add "Continue" button at bottom, disabled when no option selected, styled like Entry Screen's "Prepare" button
    - On confirm: call `LevelService.saveLevel()`, on success navigate to `/home` passing `AuthService` and `LevelService` as arguments
    - On API error: show error message in red text below button
    - Show loading overlay during API call (same pattern as Entry Screen's `_isPreparing`)
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 2.4, 3.1, 3.3_

  - [ ]* 3.2 Write property test for button enabled state (Property 1)
    - **Property 1: Confirmation button enabled state tracks selection**
    - Generate random selection states (null and three valid levels). Render LevelScreen and verify button enabled iff selection exists.
    - **Validates: Requirements 1.6**

- [ ] 4. Update AuthScreen for level gate
  - [x] 4.1 Update `lib/screens/auth_screen.dart` post-login flow
    - After successful `handleCallback()`, create `LevelService` with `_authService`
    - Call `await levelService.fetchLevel()`
    - If `levelService.currentLevel == null` → navigate to `/level` with `{'authService': _authService, 'levelService': levelService}` as arguments
    - Else → navigate to `/home` with `{'authService': _authService, 'levelService': levelService}` as arguments
    - _Requirements: 2.1, 2.2, 2.3, 4.1_

  - [ ]* 4.2 Write property test for navigation routing (Property 2)
    - **Property 2: Post-login navigation routes based on level presence**
    - Generate random level states (null and valid strings). Mock `fetchLevel()`. Verify navigation target is `/level` when null, `/home` when non-null.
    - **Validates: Requirements 2.2, 2.3, 4.3, 4.4**

- [x] 5. Checkpoint
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 6. Create SettingsScreen
  - [x] 6.1 Create `lib/screens/settings_screen.dart`
    - Create `SettingsScreen` stateful widget
    - Extract `AuthService` and `LevelService` from route arguments; redirect to `/` if missing
    - Display heading "Arabic Level" using `AppTextStyles.h1`
    - Use `LevelOptionPicker` pre-selecting `LevelService.currentLevel`
    - Add "Save" button, styled consistently with other screens
    - On save: call `LevelService.saveLevel()`, on success navigate back via `Navigator.pop()`
    - On API error: show error message in red text
    - Add back arrow / AppBar for navigation back to Entry Screen
    - Show loading overlay during API call
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7_

- [ ] 7. Update EntryScreen with settings button
  - [x] 7.1 Update `lib/screens/entry_screen.dart`
    - Extract `LevelService` from route arguments alongside `AuthService` (update argument extraction in `didChangeDependencies`)
    - Add `Icons.settings` `IconButton` in the top action bar `Row`, before the existing logout button
    - On tap: navigate to `/settings` passing `{'authService': _authService, 'levelService': _levelService}` as arguments
    - _Requirements: 5.1, 5.2_

- [ ] 8. Update routing in main.dart
  - [x] 8.1 Update `lib/main.dart`
    - Add imports for `LevelScreen` and `SettingsScreen`
    - Add `/level` route pointing to `const LevelScreen()`
    - Add `/settings` route pointing to `const SettingsScreen()`
    - _Requirements: 2.2, 2.3, 5.2_

- [x] 9. Final checkpoint
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Property tests use loop-based random generation inside standard `test()` blocks (consistent with existing project approach)
- API endpoint paths (`/users/level`) are placeholders — update when actual endpoints are confirmed
- `AuthService` and `LevelService` are passed between screens via route arguments, consistent with the existing navigation pattern
