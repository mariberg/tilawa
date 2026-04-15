# Bugfix Requirements Document

## Introduction

Three UI bugs on the session flow screens need fixing: (1) the recent sessions list on the Entry Screen displays all sessions instead of limiting to 5, (2) the loading indicator when AI is preparing a session is too small and subtle, and (3) the Prep Screen and Recitation Screen headers show a hardcoded "Surah Al-Baqarah · Pages 50–54" instead of the actual session's surah name and pages.

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN the Entry Screen loads recent sessions THEN the system displays all sessions returned by the API with no limit

1.2 WHEN the user taps "Prepare" and the AI is loading a session THEN the system shows a small 20×20 CircularProgressIndicator inside the button, which is not obvious enough to indicate loading

1.3 WHEN a session is started and the Prep Screen is displayed THEN the system shows a hardcoded header "Surah Al-Baqarah · Pages 50–54" regardless of the actual pages or surah selected

1.4 WHEN a session transitions to the Recitation Screen THEN the system shows a hardcoded header "Surah Al-Baqarah · Pages 50–54" regardless of the actual pages or surah selected

### Expected Behavior (Correct)

2.1 WHEN the Entry Screen loads recent sessions THEN the system SHALL display only the 5 most recent sessions

2.2 WHEN the user taps "Prepare" and the AI is loading a session THEN the system SHALL display a prominent spinning loading indicator centered on the screen, making it clear that the AI is processing

2.3 WHEN a session is started and the Prep Screen is displayed THEN the system SHALL show the actual surah name and page range in the header, derived from the `pages` and `surah` arguments passed via navigation

2.4 WHEN a session transitions to the Recitation Screen THEN the system SHALL show the actual surah name and page range in the header, derived from the `pages` and `surah` arguments passed via navigation

### Unchanged Behavior (Regression Prevention)

3.1 WHEN the Entry Screen has fewer than 5 recent sessions THEN the system SHALL CONTINUE TO display all available sessions without error

3.2 WHEN the Entry Screen has no recent sessions THEN the system SHALL CONTINUE TO display the "No recent sessions" message

3.3 WHEN the recent sessions are loading THEN the system SHALL CONTINUE TO show a loading indicator in the recent sessions section

3.4 WHEN the user taps a recent session row THEN the system SHALL CONTINUE TO populate the text field and handle revisit/move-on logic correctly

3.5 WHEN the Prepare button is not loading THEN the system SHALL CONTINUE TO display the "Prepare" text label in the button

3.6 WHEN the Recitation Screen "Done" button is submitting THEN the system SHALL CONTINUE TO show the existing small loading indicator inside the button

3.7 WHEN a page-based session is started (no surah) THEN the system SHALL CONTINUE TO display the pages string in the header (e.g. "Pages 50–54")

3.8 WHEN the Entry Screen hint text shows "e.g. 50–54 or Surah Al-Baqarah" THEN the system SHALL CONTINUE TO display this example text unchanged
