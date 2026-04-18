# Bugfix Requirements Document

## Introduction

After completing a session and returning to the home screen, the familiarity pill selection persists from the previous session instead of being cleared. This causes a confusing UX where the user sees a pre-selected familiarity level that doesn't reflect their intent for the next session. The `FamiliarityPills` widget maintains internal state (`_selected`) that is never reset when the entry screen is revisited via `Navigator.popUntil`.

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN a user completes a session and is navigated back to the home screen via `popUntil('/home')` THEN the system displays the previously selected familiarity pill as still selected (e.g., "Well known" remains highlighted)

1.2 WHEN the entry screen's `didPopNext()` is called after returning from a session THEN the system resets the text input and selected surah but does not reset the familiarity pill selection

1.3 WHEN the `FamiliarityPills` widget's internal `_selected` state is stale after navigation THEN the system shows a visual selection that does not match the default `_familiarity = 'New'` value in `_EntryScreenState`

### Expected Behavior (Correct)

2.1 WHEN a user completes a session and is navigated back to the home screen via `popUntil('/home')` THEN the system SHALL display no familiarity pill as selected (all pills in unselected/default state)

2.2 WHEN the entry screen's `didPopNext()` is called after returning from a session THEN the system SHALL reset the familiarity pill selection along with the text input and selected surah

2.3 WHEN the familiarity pills are reset THEN the system SHALL also reset the `_familiarity` field in `_EntryScreenState` to its default value `'New'`

### Unchanged Behavior (Regression Prevention)

3.1 WHEN a user taps a familiarity pill during normal form entry (without navigating away) THEN the system SHALL CONTINUE TO visually select that pill and update the familiarity value

3.2 WHEN a user selects a familiarity pill and then taps "Prepare" THEN the system SHALL CONTINUE TO send the selected familiarity value to the session API

3.3 WHEN the entry screen is first loaded (initial navigation, not a return) THEN the system SHALL CONTINUE TO show no familiarity pill selected by default

3.4 WHEN a user interacts with the surah typeahead or page input THEN the system SHALL CONTINUE TO function independently of the familiarity pill state
