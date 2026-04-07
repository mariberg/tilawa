# Requirements Document

## Introduction

Add a typeahead/autocomplete search feature to the Entry Screen of the Quran Prep app. When the user types a surah name into the existing text field, the app suggests matching surahs fetched from the Quran.com public API (`https://api.quran.com/api/v4/chapters`). Selecting a suggestion populates the text field with the chosen surah name. The feature replaces the current plain `TextField` with a typeahead widget while preserving the existing visual style.

## Glossary

- **Entry_Screen**: The home screen of the app (`lib/screens/entry_screen.dart`) where users specify what they are about to recite.
- **Surah_Model**: A Dart data class representing a Quran chapter with fields: `id` (int), `nameSimple` (String), `nameArabic` (String), and `translation` (String).
- **Surah_Service**: A service responsible for fetching the list of surahs from the Quran.com API.
- **Typeahead_Field**: An autocomplete text input widget that displays a dropdown of matching suggestions as the user types.
- **Suggestion_List**: The filtered dropdown list of Surah_Model items displayed beneath the Typeahead_Field.
- **Quran_API**: The public Quran.com REST API endpoint at `https://api.quran.com/api/v4/chapters` that returns chapter data in JSON format.

## Requirements

### Requirement 1: Surah Data Model

**User Story:** As a developer, I want a structured Surah data model, so that API response data can be parsed and used consistently throughout the app.

#### Acceptance Criteria

1. THE Surah_Model SHALL contain the fields: `id` (int), `nameSimple` (String), `nameArabic` (String), and `translation` (String).
2. WHEN a valid JSON map from the Quran_API chapters response is provided, THE Surah_Model SHALL parse `id` from `json['id']`, `nameSimple` from `json['name_simple']`, `nameArabic` from `json['name_arabic']`, and `translation` from `json['name_translation']['name']`.
3. IF the JSON map is missing a required field or contains a null value for a required field, THEN THE Surah_Model SHALL throw a descriptive error indicating which field is missing.

### Requirement 2: Fetch Surahs from API

**User Story:** As a user, I want the app to load the list of all surahs from the Quran.com API, so that I can search through them.

#### Acceptance Criteria

1. WHEN the Entry_Screen is initialized, THE Surah_Service SHALL send an HTTP GET request to `https://api.quran.com/api/v4/chapters`.
2. WHEN the Quran_API returns a 200 status code, THE Surah_Service SHALL parse the `chapters` array from the response body and return a list of Surah_Model instances.
3. IF the Quran_API returns a non-200 status code, THEN THE Surah_Service SHALL throw an exception with a message that includes the status code.
4. IF a network error occurs during the API call, THEN THE Surah_Service SHALL propagate the error so the caller can handle it.
5. THE Surah_Service SHALL fetch the surah list only once and cache the result in memory for subsequent lookups during the same app session.

### Requirement 3: Typeahead Suggestion Filtering

**User Story:** As a user, I want to see matching surah suggestions as I type, so that I can quickly find the surah I want to recite.

#### Acceptance Criteria

1. WHEN the user types text into the Typeahead_Field, THE Entry_Screen SHALL filter the cached surah list by matching the input against the `nameSimple` field using a case-insensitive substring match.
2. WHEN the input text is empty, THE Suggestion_List SHALL display no suggestions.
3. WHEN no surahs match the input text, THE Suggestion_List SHALL display a "No surahs found" message.
4. WHEN one or more surahs match the input text, THE Suggestion_List SHALL display each matching surah showing the `nameSimple` and `nameArabic` values.

### Requirement 4: Suggestion Selection

**User Story:** As a user, I want to select a surah from the suggestions, so that the text field is populated with my choice.

#### Acceptance Criteria

1. WHEN the user taps a suggestion in the Suggestion_List, THE Typeahead_Field SHALL populate its text with the selected surah's `nameSimple` value.
2. WHEN the user taps a suggestion in the Suggestion_List, THE Suggestion_List SHALL close.

### Requirement 5: Visual Consistency

**User Story:** As a user, I want the typeahead field to match the existing app design, so that the experience feels cohesive.

#### Acceptance Criteria

1. THE Typeahead_Field SHALL use the same font size (15), text color (AppColors.textPrimary), hint text ("e.g. 50–54 or Surah Al-Baqarah"), and underline border styling as the current TextField on the Entry_Screen.
2. THE Suggestion_List SHALL display suggestion items using AppColors.textPrimary for the `nameSimple` text and AppColors.textSecondary for the `nameArabic` text.
3. THE Suggestion_List SHALL have a white (AppColors.surface) background.

### Requirement 6: Error Handling on Entry Screen

**User Story:** As a user, I want to be informed when surah data fails to load, so that I understand why suggestions are unavailable.

#### Acceptance Criteria

1. IF the Surah_Service fails to fetch surahs, THEN THE Entry_Screen SHALL display an inline error message below the Typeahead_Field indicating that surah data could not be loaded.
2. WHILE the Surah_Service is fetching data, THE Typeahead_Field SHALL display a loading indicator in the suggestion dropdown when the user types.

### Requirement 7: Package Dependencies

**User Story:** As a developer, I want the necessary packages added to the project, so that the typeahead and HTTP functionality are available.

#### Acceptance Criteria

1. THE project SHALL include the `http` package as a dependency in `pubspec.yaml` for making API requests.
2. THE project SHALL include the `flutter_typeahead` package as a dependency in `pubspec.yaml` for the typeahead widget.
