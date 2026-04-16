# Requirements Document

## Introduction

Add cycling progress messages to the loading overlay that appears on the Entry Screen while a session is being prepared. The messages give the user a sense of progress during the API call, even though no real progress data is available. The messages rotate on a fixed timer and display beneath the existing spinner.

## Glossary

- **Entry_Screen**: The main screen (`lib/screens/entry_screen.dart`) where users enter pages or a surah name and tap "Prepare" to start a session.
- **Loading_Overlay**: The semi-transparent overlay with a `CircularProgressIndicator` shown on the Entry Screen while `_isPreparing` is true.
- **Progress_Message**: A short text string displayed below the spinner inside the Loading Overlay to indicate perceived progress.
- **Message_List**: The ordered list of four progress messages: "Analysing the passage…", "Identifying key vocabulary for your level…", "Ranking keywords by importance…", "Almost ready…".
- **Cycle_Interval**: The time duration between automatic transitions from one Progress Message to the next (2–3 seconds).

## Requirements

### Requirement 1: Display a progress message during preparation

**User Story:** As a user, I want to see a descriptive progress message while the session is being prepared, so that I feel the app is actively working rather than stalled.

#### Acceptance Criteria

1. WHILE the Loading_Overlay is visible, THE Entry_Screen SHALL display the current Progress_Message centered below the CircularProgressIndicator.
2. THE Entry_Screen SHALL render the Progress_Message using the app's existing `AppTextStyles` and `AppColors` theme tokens for visual consistency.
3. WHEN the Loading_Overlay becomes visible, THE Entry_Screen SHALL display the first message in the Message_List ("Analysing the passage…").

### Requirement 2: Cycle through progress messages on a timer

**User Story:** As a user, I want the progress message to change every few seconds, so that I perceive continuous progress during the wait.

#### Acceptance Criteria

1. WHILE the Loading_Overlay is visible, THE Entry_Screen SHALL advance to the next Progress_Message in the Message_List every 2.5 seconds.
2. WHEN the last message in the Message_List is reached, THE Entry_Screen SHALL continue displaying the last message ("Almost ready…") without cycling back to the first.
3. WHEN the Loading_Overlay is dismissed, THE Entry_Screen SHALL cancel the cycling timer and reset the message index to the first message.

### Requirement 3: Clean up timer resources

**User Story:** As a developer, I want the cycling timer to be properly disposed, so that there are no memory leaks or orphaned timers.

#### Acceptance Criteria

1. WHEN the Entry_Screen widget is disposed, THE Entry_Screen SHALL cancel any active cycling timer.
2. WHEN the prepare operation completes (success or failure), THE Entry_Screen SHALL cancel the cycling timer before hiding the Loading_Overlay.
3. IF the user navigates away from the Entry_Screen while preparing, THEN THE Entry_Screen SHALL cancel the cycling timer during disposal.

### Requirement 4: Message list content

**User Story:** As a product owner, I want the exact progress messages defined, so that the user experience is consistent and intentional.

#### Acceptance Criteria

1. THE Message_List SHALL contain exactly four messages in this order: "Analysing the passage…", "Identifying key vocabulary for your level…", "Ranking keywords by importance…", "Almost ready…".
2. THE Entry_Screen SHALL display each Progress_Message exactly as specified, including the trailing ellipsis character (…).
