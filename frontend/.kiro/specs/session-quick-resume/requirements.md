# Requirements Document

## Introduction

Make recent session rows on the Entry Screen tappable so they act as shortcuts to resume from where the user left off. Recent sessions can be either page-based or surah-based: the backend API (`GET /sessions/recent`) returns sessions with either a `pages` field (String) or a `surah` field (int), never both.

The tap behavior depends on the session's feeling value and session type:
- For page-based sessions marked "smooth" or "struggled", the text field is pre-filled with the next logical page range.
- For surah-based sessions marked "smooth" or "struggled", the text field is pre-filled with the next surah's `nameSimple` (looked up from the already-loaded surah list on Entry_Screen).
- For sessions marked "revisit", a bottom sheet offers two options: revisit the same content or move on to the next.

The "next logical page range" is computed by parsing the start and end page numbers from the session's pages string, calculating the span, and producing the next contiguous range of the same size (e.g. "Pages 50–54" → "55–59").

The "next surah" is computed as surah ID + 1. There are 114 surahs total. If the session's surah is 114 (the last surah), the next surah wraps to surah 1.

Additionally, the Entry Screen re-fetches recent sessions every time the user navigates back to it, rather than only on first load.

This feature builds on the existing `recent-sessions-display` spec which provides the RecentSession model, fetchRecentSessions service method, formatRelativeDate utility, and the dynamic recent sessions section on the Entry Screen.

## Glossary

- **Entry_Screen**: The home screen (`lib/screens/entry_screen.dart`) where users configure and start a preparation session. Holds a `_surahs` list of all 114 surahs loaded at startup.
- **Recent_Session**: A data model (`lib/models/recent_session.dart`) representing a single recent session, containing `sessionId`, `feeling`, `createdAt`, and either `pages` (String?) or `surah` (int?). Exactly one of `pages` or `surah` is present.
- **Page_Session**: A Recent_Session where the `pages` field is non-null and `surah` is null.
- **Surah_Session**: A Recent_Session where the `surah` field is non-null and `pages` is null.
- **Session_Service**: The Dart service class (`lib/services/session_service.dart`) responsible for all session-related API calls, including `fetchRecentSessions`.
- **Page_Range_Parser**: A pure utility function that extracts the start page, end page, and span from a Recent_Session pages string.
- **Next_Page_Range_Calculator**: A pure utility function that computes the next contiguous page range given a start page, end page, and span.
- **Surah_Model**: The data model (`lib/models/surah.dart`) with fields `id` (int), `nameSimple` (String), `nameArabic` (String), and `translation` (String).
- **Surah_List**: The `_surahs` state variable on Entry_Screen, a list of all 114 Surah_Model instances loaded at startup.
- **Revisit_Bottom_Sheet**: A modal bottom sheet displayed when the user taps a recent session whose feeling is `revisit`, offering two options to revisit or move on.
- **Text_Field**: The text input field on the Entry_Screen where the user enters pages or a surah name (controlled by `_textController`).
- **Feeling_Value**: One of three valid string values representing the user's session feedback: `smooth`, `struggled`, `revisit`.

## Requirements

### Requirement 1: RecentSession Model Supports Both Session Types

**User Story:** As a developer, I want the RecentSession model to represent both page-based and surah-based sessions, so that the UI can handle either type from the API.

#### Acceptance Criteria

1. THE Recent_Session model SHALL have an optional `pages` field of type String?.
2. THE Recent_Session model SHALL have an optional `surah` field of type int?.
3. WHEN deserializing a JSON object from the API, THE Recent_Session model SHALL accept a response containing `pages` without `surah` as a valid Page_Session.
4. WHEN deserializing a JSON object from the API, THE Recent_Session model SHALL accept a response containing `surah` without `pages` as a valid Surah_Session.
5. IF a JSON object contains neither `pages` nor `surah`, THEN THE Recent_Session model SHALL throw a FormatException.

### Requirement 2: Display Recent Session Rows for Both Types

**User Story:** As a user, I want to see my recent sessions listed with the correct label regardless of whether they were page-based or surah-based, so that I can identify each session at a glance.

#### Acceptance Criteria

1. WHEN a recent session is a Page_Session, THE Entry_Screen SHALL display the `pages` string as the row title.
2. WHEN a recent session is a Surah_Session, THE Entry_Screen SHALL look up the surah's `nameSimple` from the Surah_List using the session's `surah` field and display that as the row title.
3. IF a Surah_Session's surah ID cannot be found in the Surah_List, THEN THE Entry_Screen SHALL display a fallback label "Surah {id}" where {id} is the surah number.

### Requirement 3: Parse Page Range from Session

**User Story:** As a developer, I want to extract structured page numbers from a session's pages string, so that the next page range can be computed.

#### Acceptance Criteria

1. WHEN a pages string in the format "Pages {start}–{end}" is provided, THE Page_Range_Parser SHALL return the start page number, end page number, and span (end - start + 1).
2. WHEN a pages string in the format "{start}-{end}" or "{start}–{end}" (without the "Pages " prefix) is provided, THE Page_Range_Parser SHALL return the start page number, end page number, and span.
3. WHEN a pages string contains a single page number (e.g. "Pages 50" or "50"), THE Page_Range_Parser SHALL return that number as both start and end, with a span of 1.
4. IF the pages string cannot be parsed into valid page numbers, THEN THE Page_Range_Parser SHALL return null to indicate an unparseable input.
5. FOR ALL valid pages strings, parsing then formatting back to a range string SHALL produce a string that parses to the same start and end values (round-trip property).

### Requirement 4: Compute Next Logical Page Range

**User Story:** As a user, I want the app to suggest the next set of pages after my last session, so that I can continue my practice seamlessly.

#### Acceptance Criteria

1. WHEN given a start page and end page, THE Next_Page_Range_Calculator SHALL produce a string "{nextStart}-{nextEnd}" where nextStart equals end + 1 and nextEnd equals end + span.
2. WHEN the session covered pages 50–54 (span of 5), THE Next_Page_Range_Calculator SHALL produce "55-59".
3. WHEN the session covered a single page (e.g. page 50, span of 1), THE Next_Page_Range_Calculator SHALL produce "51" as the next range.

### Requirement 5: Compute Next Surah

**User Story:** As a user, I want the app to suggest the next surah after my last surah-based session, so that I can continue my practice seamlessly.

#### Acceptance Criteria

1. WHEN given a surah number N where N is less than 114, THE Entry_Screen SHALL compute the next surah as N + 1.
2. WHEN given surah number 114, THE Entry_Screen SHALL wrap the next surah to 1.
3. THE Entry_Screen SHALL look up the next surah's `nameSimple` from the Surah_List to produce the pre-fill string.

### Requirement 6: Tap Behavior for Non-Revisit Page Sessions

**User Story:** As a user, I want to tap a page-based recent session marked "smooth" or "struggled" and have the next page range filled in automatically, so that I can quickly start my next session.

#### Acceptance Criteria

1. WHEN the user taps a Page_Session row whose feeling is `smooth` or `struggled`, THE Entry_Screen SHALL pre-fill the Text_Field with the next logical page range computed from that session's pages.
2. WHEN the user taps a Page_Session row whose feeling is `smooth` or `struggled`, THE Entry_Screen SHALL NOT display the Revisit_Bottom_Sheet.
3. IF the pages string of the tapped Page_Session cannot be parsed, THEN THE Entry_Screen SHALL take no action on the Text_Field.

### Requirement 7: Tap Behavior for Non-Revisit Surah Sessions

**User Story:** As a user, I want to tap a surah-based recent session marked "smooth" or "struggled" and have the next surah name filled in automatically, so that I can quickly start my next session.

#### Acceptance Criteria

1. WHEN the user taps a Surah_Session row whose feeling is `smooth` or `struggled`, THE Entry_Screen SHALL pre-fill the Text_Field with the next surah's `nameSimple` (computed per Requirement 5).
2. WHEN the user taps a Surah_Session row whose feeling is `smooth` or `struggled`, THE Entry_Screen SHALL NOT display the Revisit_Bottom_Sheet.
3. IF the next surah's ID cannot be found in the Surah_List, THEN THE Entry_Screen SHALL take no action on the Text_Field.

### Requirement 8: Tap Behavior for Revisit Page Sessions

**User Story:** As a user, I want to tap a page-based recent session marked "revisit" and choose whether to revisit the same pages or move on, so that I can decide based on how I feel about that content.

#### Acceptance Criteria

1. WHEN the user taps a Page_Session row whose feeling is `revisit`, THE Entry_Screen SHALL display the Revisit_Bottom_Sheet.
2. THE Revisit_Bottom_Sheet SHALL present exactly two options: "Revisit same pages" and "Move on".
3. WHEN the user selects "Revisit same pages", THE Entry_Screen SHALL pre-fill the Text_Field with the same page range from that session (formatted as "{start}-{end}").
4. WHEN the user selects "Move on", THE Entry_Screen SHALL pre-fill the Text_Field with the next logical page range computed from that session's pages.
5. WHEN the user dismisses the Revisit_Bottom_Sheet without selecting an option, THE Entry_Screen SHALL leave the Text_Field unchanged.
6. IF the pages string of the tapped Page_Session cannot be parsed, THEN THE Entry_Screen SHALL take no action and SHALL NOT display the Revisit_Bottom_Sheet.

### Requirement 9: Tap Behavior for Revisit Surah Sessions

**User Story:** As a user, I want to tap a surah-based recent session marked "revisit" and choose whether to revisit the same surah or move on to the next, so that I can decide based on how I feel about that content.

#### Acceptance Criteria

1. WHEN the user taps a Surah_Session row whose feeling is `revisit`, THE Entry_Screen SHALL display the Revisit_Bottom_Sheet.
2. THE Revisit_Bottom_Sheet SHALL present exactly two options: "Revisit same surah" and "Move on".
3. WHEN the user selects "Revisit same surah", THE Entry_Screen SHALL pre-fill the Text_Field with the current surah's `nameSimple` (looked up from the Surah_List).
4. WHEN the user selects "Move on", THE Entry_Screen SHALL pre-fill the Text_Field with the next surah's `nameSimple` (computed per Requirement 5).
5. WHEN the user dismisses the Revisit_Bottom_Sheet without selecting an option, THE Entry_Screen SHALL leave the Text_Field unchanged.
6. IF the surah ID of the tapped Surah_Session cannot be found in the Surah_List, THEN THE Entry_Screen SHALL take no action and SHALL NOT display the Revisit_Bottom_Sheet.

### Requirement 10: Re-fetch Recent Sessions on Navigation Return

**User Story:** As a user, I want the Entry Screen to refresh my recent sessions every time I come back to it, so that I always see up-to-date data after completing a session.

#### Acceptance Criteria

1. WHEN the user navigates back to the Entry_Screen (e.g. after completing a session), THE Entry_Screen SHALL call `fetchRecentSessions` on the Session_Service to refresh the recent sessions list.
2. WHILE the re-fetch is in progress, THE Entry_Screen SHALL display a loading indicator in the recent sessions section.
3. IF the re-fetch fails, THEN THE Entry_Screen SHALL display a short error message in the recent sessions section.
4. THE Entry_Screen SHALL replace the previously displayed recent sessions with the newly fetched data upon a successful re-fetch.

### Requirement 11: Recent Session Rows are Tappable

**User Story:** As a user, I want recent session rows to look and feel interactive, so that I know I can tap them.

#### Acceptance Criteria

1. THE Entry_Screen SHALL render each recent session row as a tappable widget that responds to user taps.
2. THE Entry_Screen SHALL provide visual tap feedback (e.g. ink splash or opacity change) when a recent session row is tapped.
