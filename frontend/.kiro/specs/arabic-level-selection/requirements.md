# Requirements Document

## Introduction

Add an Arabic level selection flow to the Quran Prep app. When a user logs in for the first time (no Arabic level stored), the app presents a full-screen selection page before navigating to the Entry Screen. The user chooses from three levels displayed as friendly labels: "I'm a beginner", "I can follow along", and "I read with understanding", which map to the internal values beginner, intermediate, and advanced respectively. The selected level is persisted to the backend database via an API call (endpoint details to be provided). A settings button is added to the Entry Screen so users can revisit and change their Arabic level at any time.

## Glossary

- **Auth_Screen**: The login screen (`lib/screens/auth_screen.dart`) where users authenticate via OAuth2.
- **Entry_Screen**: The home screen (`lib/screens/entry_screen.dart`) where users configure and start a preparation session.
- **Level_Screen**: A new full-screen page (`lib/screens/level_screen.dart`) that presents the Arabic level selection options.
- **Settings_Screen**: A new screen (`lib/screens/settings_screen.dart`) where users can modify their Arabic level after initial selection.
- **Auth_Service**: The Dart service class (`lib/services/auth_service.dart`) responsible for OAuth2 tokens and user identity.
- **Level_Service**: A new Dart service class (`lib/services/level_service.dart`) responsible for fetching and saving the Arabic level via the backend API.
- **Arabic_Level**: One of three internal values representing the user's Arabic proficiency: `beginner`, `intermediate`, or `advanced`.
- **AppColors**: The static color constants class (`lib/theme/app_colors.dart`) used across the app.
- **AppTextStyles**: The static text style constants class (`lib/theme/app_text_styles.dart`) used across the app.

## Requirements

### Requirement 1: Arabic Level Selection Screen

**User Story:** As a user, I want to see a dedicated screen asking for my Arabic level after my first login, so that the app can tailor my experience.

#### Acceptance Criteria

1. THE Level_Screen SHALL display a heading asking the user to select their Arabic level.
2. THE Level_Screen SHALL display three selectable options with the following labels: "I'm a beginner", "I can follow along", and "I read with understanding".
3. THE Level_Screen SHALL map the label "I'm a beginner" to the Arabic_Level value `beginner`, "I can follow along" to `intermediate`, and "I read with understanding" to `advanced`.
4. WHEN the user taps one of the three options, THE Level_Screen SHALL visually highlight the selected option.
5. THE Level_Screen SHALL display a confirmation button that submits the selected Arabic_Level.
6. WHILE no option is selected, THE Level_Screen SHALL disable the confirmation button.
7. THE Level_Screen SHALL use colors from AppColors and text styles from AppTextStyles consistent with the Auth_Screen and Entry_Screen.

### Requirement 2: First-Login Level Gate

**User Story:** As a user, I want to be prompted for my Arabic level before reaching the session page on first login, so that the app knows my proficiency from the start.

#### Acceptance Criteria

1. WHEN OAuth2 login succeeds, THE Auth_Screen SHALL check whether the authenticated user has a stored Arabic_Level by calling Level_Service.
2. IF the user has no stored Arabic_Level, THEN THE Auth_Screen SHALL navigate to the Level_Screen instead of the Entry_Screen.
3. IF the user has a stored Arabic_Level, THEN THE Auth_Screen SHALL navigate directly to the Entry_Screen.
4. WHEN the user selects and confirms an Arabic_Level on the Level_Screen, THE Level_Screen SHALL navigate to the Entry_Screen.

### Requirement 3: Persist Arabic Level to Database

**User Story:** As a user, I want my Arabic level saved to the database, so that the app remembers my selection across sessions.

#### Acceptance Criteria

1. WHEN the user confirms an Arabic_Level on the Level_Screen, THE Level_Service SHALL send the selected Arabic_Level to the backend API.
2. WHEN the API call succeeds, THE Level_Service SHALL store the Arabic_Level locally in memory for the current session.
3. IF the API call fails, THEN THE Level_Screen SHALL display an error message indicating the level could not be saved.
4. THE Level_Service SHALL use authentication headers from Auth_Service for all API requests.

### Requirement 4: Fetch Arabic Level on Login

**User Story:** As a developer, I want the app to fetch the user's Arabic level after login, so that the app can determine whether to show the level selection screen.

#### Acceptance Criteria

1. WHEN OAuth2 login succeeds, THE Level_Service SHALL fetch the user's stored Arabic_Level from the backend API.
2. WHEN the fetch succeeds and returns an Arabic_Level, THE Level_Service SHALL store the Arabic_Level locally in memory.
3. WHEN the fetch succeeds and returns no Arabic_Level, THE Level_Service SHALL indicate that no level is set.
4. IF the fetch fails, THEN THE Level_Service SHALL treat the user as having no stored Arabic_Level, causing the Level_Screen to be shown.

### Requirement 5: Settings Button on Entry Screen

**User Story:** As a user, I want a settings button on the session page, so that I can access settings to change my Arabic level later.

#### Acceptance Criteria

1. THE Entry_Screen SHALL display a settings icon button in the top action bar alongside the existing logout button.
2. WHEN the user taps the settings icon button, THE Entry_Screen SHALL navigate to the Settings_Screen.

### Requirement 6: Modify Arabic Level from Settings

**User Story:** As a user, I want to change my Arabic level from the settings page, so that I can update my proficiency as I improve.

#### Acceptance Criteria

1. THE Settings_Screen SHALL display the same three Arabic level options as the Level_Screen: "I'm a beginner", "I can follow along", and "I read with understanding".
2. THE Settings_Screen SHALL pre-select the user's current Arabic_Level when the screen loads.
3. WHEN the user selects a different Arabic_Level and taps the save button, THE Level_Service SHALL send the updated Arabic_Level to the backend API.
4. WHEN the API call succeeds, THE Level_Service SHALL update the locally stored Arabic_Level.
5. IF the API call fails, THEN THE Settings_Screen SHALL display an error message indicating the level could not be updated.
6. THE Settings_Screen SHALL provide a way to navigate back to the Entry_Screen.
7. THE Settings_Screen SHALL use colors from AppColors and text styles from AppTextStyles consistent with the rest of the app.

### Requirement 7: Level Service Integration

**User Story:** As a developer, I want a dedicated service for Arabic level operations, so that level-related API calls are encapsulated and reusable.

#### Acceptance Criteria

1. THE Level_Service SHALL accept an Auth_Service instance for obtaining authentication headers.
2. THE Level_Service SHALL expose a method to fetch the user's Arabic_Level from the backend API.
3. THE Level_Service SHALL expose a method to save or update the user's Arabic_Level via the backend API.
4. THE Level_Service SHALL expose a getter for the currently stored Arabic_Level, returning null when no level is set.
