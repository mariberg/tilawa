# Requirements Document

## Introduction

Limit the number of keywords displayed to the user during a session to exactly 7 at a time. The backend returns a longer list of keywords in the session prepare response, but the frontend only presents 7 to the user. When the user marks a keyword as "known", that keyword is replaced with the next available keyword from the backend's full list, maintaining a visible set of 7 until no more replacement keywords remain. Additionally, the system tracks the user's categorization of each keyword throughout the session (known, not_sure, or review) and submits the complete keyword selection results along with the session scope (pages or surah) to the backend when the session is completed.

## Glossary

- **Keyword_Display_Manager**: The frontend logic responsible for managing which 7 keywords from the full backend list are currently visible to the user.
- **Visible_Keywords**: The subset of keywords (maximum 7) currently displayed to the user in the prep screen.
- **Full_Keyword_List**: The complete list of keywords returned by the backend in the session prepare response.
- **Reserve_Keywords**: Keywords from the Full_Keyword_List that are not currently in the Visible_Keywords set and are available as replacements.
- **Known_Action**: The user action of marking a keyword as "known" by tapping the "✓ Known" button on a flipped keyword card.
- **Prep_Screen**: The screen that displays keyword flashcards to the user during session preparation.
- **Display_Limit**: The constant value of 7, representing the maximum number of keywords shown to the user at one time.
- **Keyword_Category**: The user's classification of a keyword, one of three values: "known", "not_sure", or "review".
- **Keyword_Selection_Record**: A data entry associating a keyword with the Keyword_Category assigned by the user during the session.
- **Selection_Tracker**: The frontend logic responsible for recording and maintaining the Keyword_Category for each keyword the user interacts with during the session.
- **Session_Result_Payload**: The data structure sent to the backend upon session completion, containing the session scope (pages or surah) and the list of Keyword_Selection_Records.
- **Session_Completion**: The event triggered when the user finishes interacting with all Visible_Keywords and navigates to the recitation screen.

## Requirements

### Requirement 1: Initial Keyword Display Limit

**User Story:** As a user, I want to see only 7 keywords at a time, so that I am not overwhelmed by too many keywords during my session preparation.

#### Acceptance Criteria

1. WHEN the Prep_Screen loads with a Full_Keyword_List, THE Keyword_Display_Manager SHALL select the first 7 keywords from the Full_Keyword_List as the initial Visible_Keywords.
2. WHEN the Full_Keyword_List contains fewer than 7 keywords, THE Keyword_Display_Manager SHALL display all available keywords without padding or error.
3. THE Prep_Screen SHALL display the count indicator as "X of Y" where X is the current card position within the Visible_Keywords and Y is the total number of Visible_Keywords.

### Requirement 2: Keyword Replacement on Known Action

**User Story:** As a user, I want a keyword I already know to be replaced with a new one, so that I can focus my study time on unfamiliar keywords.

#### Acceptance Criteria

1. WHEN the user performs a Known_Action on a keyword, THE Keyword_Display_Manager SHALL remove that keyword from the Visible_Keywords.
2. WHEN a keyword is removed from the Visible_Keywords and Reserve_Keywords is not empty, THE Keyword_Display_Manager SHALL insert the next keyword from Reserve_Keywords into the Visible_Keywords at the same position as the removed keyword.
3. WHEN a keyword is removed from the Visible_Keywords and Reserve_Keywords is empty, THE Keyword_Display_Manager SHALL reduce the Visible_Keywords count by one.
4. AFTER a keyword replacement, THE Prep_Screen SHALL display the replacement keyword in the same card position without advancing to the next card.

### Requirement 3: Reserve Keyword Management

**User Story:** As a developer, I want the reserve keyword pool managed correctly, so that replacement keywords are drawn in order and without duplication.

#### Acceptance Criteria

1. THE Keyword_Display_Manager SHALL maintain the Reserve_Keywords as an ordered list containing all keywords from the Full_Keyword_List that are not in the Visible_Keywords.
2. WHEN a Reserve_Keyword is used as a replacement, THE Keyword_Display_Manager SHALL remove that keyword from the Reserve_Keywords.
3. THE Keyword_Display_Manager SHALL preserve the original ordering from the Full_Keyword_List when selecting Reserve_Keywords for replacement.

### Requirement 4: Non-Known Actions Preserve Current Behavior

**User Story:** As a user, I want the "Not sure" and "Review" actions to continue working as they do today, so that only the "Known" action triggers keyword replacement.

#### Acceptance Criteria

1. WHEN the user selects "Not sure" on a keyword, THE Prep_Screen SHALL advance to the next keyword card without replacing the current keyword.
2. WHEN the user selects "Review" on a keyword, THE Prep_Screen SHALL advance to the next keyword card without replacing the current keyword.

### Requirement 5: Navigation and Progress Tracking

**User Story:** As a user, I want the dot indicator and card counter to reflect the current set of visible keywords, so that I can track my progress accurately.

#### Acceptance Criteria

1. THE Prep_Screen SHALL render the dot indicator with a count equal to the current number of Visible_Keywords.
2. WHEN a keyword is replaced, THE Prep_Screen SHALL update the dot indicator count to reflect the current number of Visible_Keywords.
3. WHEN the user reaches the last Visible_Keyword and performs any action, THE Prep_Screen SHALL navigate to the recitation screen.

### Requirement 6: Display Limit Constant

**User Story:** As a developer, I want the display limit defined as a single constant, so that it can be adjusted in the future without modifying multiple code locations.

#### Acceptance Criteria

1. THE Keyword_Display_Manager SHALL define the Display_Limit as a single named constant with the value 7.
2. THE Keyword_Display_Manager SHALL reference the Display_Limit constant in all logic that determines how many keywords to display.

### Requirement 7: Keyword Selection Tracking

**User Story:** As a user, I want my categorization of each keyword recorded during the session, so that my progress is captured accurately for submission.

#### Acceptance Criteria

1. WHEN the user performs a Known_Action on a keyword, THE Selection_Tracker SHALL record a Keyword_Selection_Record with the Keyword_Category "known" for that keyword.
2. WHEN the user selects "Not sure" on a keyword, THE Selection_Tracker SHALL record a Keyword_Selection_Record with the Keyword_Category "not_sure" for that keyword.
3. WHEN the user selects "Review" on a keyword, THE Selection_Tracker SHALL record a Keyword_Selection_Record with the Keyword_Category "review" for that keyword.
4. THE Selection_Tracker SHALL maintain all Keyword_Selection_Records in memory for the duration of the session.
5. THE Selection_Tracker SHALL store exactly one Keyword_Selection_Record per keyword that the user interacted with during the session.
6. IF the user categorizes the same keyword more than once during the session, THEN THE Selection_Tracker SHALL retain only the most recent Keyword_Category for that keyword.

### Requirement 8: Session Completion Submission

**User Story:** As a user, I want my keyword categorizations sent to the backend when the session is completed, so that my progress is saved and available for future sessions.

#### Acceptance Criteria

1. WHEN Session_Completion occurs, THE Session_Service SHALL send an HTTP POST request to the backend containing the Session_Result_Payload.
2. THE Session_Result_Payload SHALL include the session scope: either the pages or the surah that the user selected for the session.
3. THE Session_Result_Payload SHALL include a list of Keyword_Selection_Records, where each record contains the keyword identifier and the Keyword_Category assigned by the user.
4. THE Session_Result_Payload SHALL include a Keyword_Selection_Record for every keyword the user interacted with during the session.
5. IF the backend returns a non-200 status code in response to the Session_Result_Payload, THEN THE Session_Service SHALL throw an exception with a message that includes the status code.
6. IF a network error occurs during submission of the Session_Result_Payload, THEN THE Session_Service SHALL propagate the error so the caller can handle the failure.

### Requirement 9: Selection State Integrity

**User Story:** As a developer, I want the keyword selection state managed reliably, so that no user categorizations are lost during the session.

#### Acceptance Criteria

1. THE Selection_Tracker SHALL initialize with an empty set of Keyword_Selection_Records when a new session begins.
2. THE Selection_Tracker SHALL preserve all Keyword_Selection_Records across keyword replacements triggered by the Known_Action.
3. WHEN Session_Completion occurs, THE Selection_Tracker SHALL provide the complete list of Keyword_Selection_Records to the Session_Service for submission.
4. THE Selection_Tracker SHALL associate each Keyword_Selection_Record with the keyword's `arabic` field as the unique identifier.
