# Requirements Document

## Introduction

Simplify the keyword rating interaction on the prep screen by reducing the three rating categories ("Known", "Not sure", "Review") to two categories ("Known", "Not known"). This streamlines the user experience by removing the ambiguous distinction between "Not sure" and "Review", consolidating them into a single "Not known" action. The change touches the prep screen UI, the selection tracker, the keyword display manager integration, and the session result payload sent to the API.

## Glossary

- **Prep_Screen**: The screen where users review keyword flashcards before a recitation session
- **Keyword_Card**: A flashcard UI element displaying an Arabic keyword; tapping it flips to reveal the translation
- **Selection_Tracker**: The service that records the user's rating for each keyword during a prep session
- **Keyword_Display_Manager**: The service that manages the visible keyword list and handles replacement of known keywords with reserve keywords
- **Session_Result_Payload**: The data structure sent to the API containing keyword ratings and session metadata
- **Keyword_Selection_Record**: The model representing a single keyword's rating, containing arabic text, translation, and status

## Requirements

### Requirement 1: Two-Button Rating UI

**User Story:** As a user, I want to see only two rating options after flipping a keyword card, so that I can make a quicker and clearer decision about my knowledge of each keyword.

#### Acceptance Criteria

1. WHEN a Keyword_Card is flipped, THE Prep_Screen SHALL display exactly two action buttons: "Known" and "Not known"
2. WHEN a Keyword_Card is not flipped, THE Prep_Screen SHALL hide all rating action buttons
3. THE Prep_Screen SHALL remove the "Not sure" and "Review" action buttons from the rating UI

### Requirement 2: "Known" Button Behavior

**User Story:** As a user, I want the "Known" button to replace the current card with the next keyword from the reserve queue, so that I only continue reviewing keywords I have not yet learned.

#### Acceptance Criteria

1. WHEN the user taps the "Known" button, THE Selection_Tracker SHALL record the keyword with a status of "known"
2. WHEN the user taps the "Known" button, THE Keyword_Display_Manager SHALL replace the current keyword at the same index with the next keyword from the reserve queue
3. WHEN the user taps the "Known" button and no reserve keywords remain, THE Keyword_Display_Manager SHALL remove the current keyword from the visible list, reducing the total visible count by one
4. WHEN the user taps the "Known" button on the last remaining keyword, THE Prep_Screen SHALL complete the session and navigate to the recitation screen

### Requirement 3: "Not known" Button Behavior

**User Story:** As a user, I want the "Not known" button to advance to the next card without replacing it, so that I can revisit keywords I have not yet learned.

#### Acceptance Criteria

1. WHEN the user taps the "Not known" button, THE Selection_Tracker SHALL record the keyword with a status of "not_known"
2. WHEN the user taps the "Not known" button, THE Prep_Screen SHALL advance to the next keyword card without replacing the current card
3. WHEN the user taps the "Not known" button on the last visible keyword card, THE Prep_Screen SHALL complete the session and navigate to the recitation screen

### Requirement 4: Updated Status Values in Selection Tracker

**User Story:** As a developer, I want the selection tracker to only accept the new status values, so that the data model is consistent with the simplified rating system.

#### Acceptance Criteria

1. THE Selection_Tracker SHALL accept only two status values: "known" and "not_known"
2. THE Selection_Tracker SHALL no longer accept the "not_sure" or "review" status values
3. FOR ALL recorded keywords, THE Selection_Tracker SHALL produce Keyword_Selection_Record objects with a status field containing either "known" or "not_known"

### Requirement 5: Session Result Payload Compatibility

**User Story:** As a developer, I want the session result payload to transmit the new status values to the API, so that the backend receives consistent rating data.

#### Acceptance Criteria

1. WHEN a session is completed, THE Session_Result_Payload SHALL include keyword records with status values of "known" or "not_known" only
2. THE Keyword_Selection_Record SHALL serialize the status field as "known" or "not_known" in the JSON output
3. WHEN a Session_Result_Payload is deserialized, THE Keyword_Selection_Record SHALL accept "known" and "not_known" as valid status values

### Requirement 6: Card State Management Cleanup

**User Story:** As a developer, I want the internal card state mapping to reflect only two states, so that the code is clean and maintainable.

#### Acceptance Criteria

1. THE Prep_Screen SHALL map the "Known" button to state value 1 and the "Not known" button to state value 2
2. THE Prep_Screen SHALL remove the state value 3 mapping previously used for the "Review" button
3. WHEN state value 2 is triggered, THE Prep_Screen SHALL invoke the advance-to-next-card behavior (previously shared by "Not sure" and "Review")
