# Familiarity Reset on Return Bugfix Design

## Overview

The FamiliarityPills widget uses internal StatefulWidget state (`_selected`) that persists across navigation cycles. When the user completes a session and returns to the entry screen via `Navigator.popUntil`, the `didPopNext()` callback resets the text input and selected surah but has no mechanism to reset the familiarity pills. The fix introduces a `GlobalKey<_FamiliarityPillsState>` so the parent can call a `reset()` method on the widget, and also resets `_familiarity` back to `'New'` in `_EntryScreenState.didPopNext()`.

## Glossary

- **Bug_Condition (C)**: The condition where `didPopNext()` fires on `_EntryScreenState` after returning from a completed session, but the FamiliarityPills widget retains its previous `_selected` value
- **Property (P)**: After `didPopNext()`, all familiarity pills should be visually unselected and `_familiarity` should equal `'New'`
- **Preservation**: Normal pill selection during form entry, API submission of familiarity value, initial screen load state, and surah/page input independence must remain unchanged
- **FamiliarityPills**: StatefulWidget in `lib/widgets/familiarity_pills.dart` that renders selectable pill buttons for familiarity levels
- **_EntryScreenState**: State class in `lib/screens/entry_screen.dart` that manages the home screen form including familiarity selection

## Bug Details

### Bug Condition

The bug manifests when a user completes a session flow (entry → prep → session → feedback) and is navigated back to the entry screen via `Navigator.popUntil(context, ModalRoute.withName('/home'))`. The `_EntryScreenState.didPopNext()` fires and resets text input and selected surah, but the `FamiliarityPills` widget's internal `_selected` index remains at its previous value. Additionally, `_familiarity` in `_EntryScreenState` is not reset to `'New'`.

**Formal Specification:**
```
FUNCTION isBugCondition(input)
  INPUT: input of type NavigationEvent
  OUTPUT: boolean

  RETURN input.type == 'popUntil'
         AND input.targetRoute == '/home'
         AND entryScreenState.didPopNext() is called
         AND familiarityPillsState._selected != -1
END FUNCTION
```

### Examples

- User selects "Well known", completes session, returns to home → "Well known" pill is still highlighted (expected: no pill selected)
- User selects "Somewhat familiar", prepares, finishes feedback, pops back → "Somewhat familiar" persists visually, but `_familiarity` may still hold the old value (expected: pills cleared, `_familiarity` = `'New'`)
- User selects "New" explicitly, completes flow, returns → pill index 0 is still selected visually even though it matches the default value semantically (expected: no pill visually selected, index = -1)
- User never selects a pill, completes flow, returns → no visual issue since `_selected` is already -1 (edge case, no bug)

## Expected Behavior

### Preservation Requirements

**Unchanged Behaviors:**
- Tapping a familiarity pill during normal form entry must continue to visually select it and call `onChanged`
- The selected familiarity value must continue to be sent to the session API via `_prepare()`
- Initial screen load (first navigation to `/home`) must continue to show no pill selected
- Surah typeahead and page input must continue to function independently of familiarity state

**Scope:**
All interactions that do NOT involve returning to the entry screen via `popUntil` should be completely unaffected by this fix. This includes:
- Normal pill selection and deselection during form entry
- Prepare button submission with selected familiarity
- Navigation to settings or other screens that don't trigger `didPopNext`

## Hypothesized Root Cause

Based on the bug description, the most likely issues are:

1. **No external reset mechanism on FamiliarityPills**: The widget is a StatefulWidget with purely internal state (`_selected`). There is no `GlobalKey`, callback, or controller pattern that allows the parent to trigger a reset. The parent has no way to communicate "clear your selection" to the child.

2. **Incomplete reset in didPopNext()**: `_EntryScreenState.didPopNext()` resets `_textController`, `_selectedSurah`, and `_error`, but does not reset `_familiarity` back to `'New'` and has no reference to the FamiliarityPills state.

3. **Widget not rebuilt from scratch**: Because the EntryScreen is not destroyed and recreated (it stays in the navigation stack), the FamiliarityPills widget's State object persists. Flutter does not call `initState` again, so `_selected` retains its value.

## Correctness Properties

Property 1: Bug Condition - Familiarity Pills Reset After Return

_For any_ navigation event where `didPopNext()` is called on `_EntryScreenState` after returning from a completed session, the fixed code SHALL reset the FamiliarityPills widget's `_selected` to -1 (no selection) and reset `_EntryScreenState._familiarity` to `'New'`.

**Validates: Requirements 2.1, 2.2, 2.3**

Property 2: Preservation - Normal Pill Selection Behavior

_For any_ user interaction that is NOT a return-from-session navigation (i.e., normal pill taps during form entry, prepare submission, initial load), the fixed code SHALL produce exactly the same behavior as the original code, preserving pill selection visuals, `onChanged` callbacks, and API submission of the familiarity value.

**Validates: Requirements 3.1, 3.2, 3.3, 3.4**

## Fix Implementation

### Changes Required

Assuming our root cause analysis is correct:

**File**: `lib/widgets/familiarity_pills.dart`

**Changes**:
1. **Add a public `reset()` method** to `_FamiliarityPillsState` that sets `_selected = -1` inside `setState`

**File**: `lib/screens/entry_screen.dart`

**Changes**:
1. **Add a `GlobalKey<_FamiliarityPillsState>`** field to `_EntryScreenState` — however, `_FamiliarityPillsState` is private. Two approaches:
   - **Option A (chosen)**: Make `_FamiliarityPillsState` public by renaming to `FamiliarityPillsState`, then use `GlobalKey<FamiliarityPillsState>` in the parent
   - **Option B**: Use a `ValueNotifier<int>` or callback pattern instead of GlobalKey

2. **Pass the GlobalKey** to the `FamiliarityPills` widget constructor in the build method

3. **Call reset in didPopNext()**: Add `_familiarityKey.currentState?.reset()` to the `didPopNext()` method

4. **Reset `_familiarity`**: Add `_familiarity = 'New'` to the `didPopNext()` method's `setState` block

## Testing Strategy

### Validation Approach

The testing strategy follows a two-phase approach: first, surface counterexamples that demonstrate the bug on unfixed code, then verify the fix works correctly and preserves existing behavior.

### Exploratory Bug Condition Checking

**Goal**: Surface counterexamples that demonstrate the bug BEFORE implementing the fix. Confirm or refute the root cause analysis.

**Test Plan**: Write a widget test that simulates the full navigation cycle: render EntryScreen, tap a familiarity pill, simulate `didPopNext()`, and assert the pill visual state and `_familiarity` value.

**Test Cases**:
1. **Pill persists after didPopNext**: Select "Well known", trigger didPopNext, verify pill is still selected (will fail on unfixed code — demonstrates the bug)
2. **_familiarity not reset**: Select "Somewhat familiar", trigger didPopNext, verify `_familiarity` still holds old value (will fail on unfixed code)
3. **Multiple round trips**: Select pill, didPopNext, select again, didPopNext — verify state accumulates incorrectly (will fail on unfixed code)

**Expected Counterexamples**:
- After didPopNext, `_FamiliarityPillsState._selected` is not -1
- After didPopNext, `_EntryScreenState._familiarity` is not 'New'

### Fix Checking

**Goal**: Verify that for all inputs where the bug condition holds, the fixed function produces the expected behavior.

**Pseudocode:**
```
FOR ALL input WHERE isBugCondition(input) DO
  result := didPopNext_fixed(input)
  ASSERT familiarityPillsState._selected == -1
  ASSERT entryScreenState._familiarity == 'New'
  ASSERT no pill is visually highlighted
END FOR
```

### Preservation Checking

**Goal**: Verify that for all inputs where the bug condition does NOT hold, the fixed function produces the same result as the original function.

**Pseudocode:**
```
FOR ALL input WHERE NOT isBugCondition(input) DO
  ASSERT originalBehavior(input) == fixedBehavior(input)
END FOR
```

**Testing Approach**: Property-based testing is recommended for preservation checking because:
- It generates many test cases automatically across the input domain
- It catches edge cases that manual unit tests might miss
- It provides strong guarantees that behavior is unchanged for all non-buggy inputs

**Test Plan**: Observe behavior on UNFIXED code first for normal pill selection and API submission, then write tests capturing that behavior.

**Test Cases**:
1. **Pill selection preservation**: Verify tapping pills updates visual state and calls onChanged correctly after fix
2. **API value preservation**: Verify the familiarity value sent to prepare API matches the selected pill
3. **Initial state preservation**: Verify first load shows no pill selected and _familiarity defaults to 'New'

### Unit Tests

- Test `FamiliarityPillsState.reset()` sets `_selected` to -1
- Test `didPopNext()` calls reset on the pills and resets `_familiarity`
- Test pill tap still works after a reset cycle

### Property-Based Tests

- Generate random sequences of pill selections and resets, verify state is always consistent
- Generate random navigation cycles, verify familiarity is always 'New' after each return

### Integration Tests

- Test full flow: select pill → prepare → feedback → popUntil → verify reset
- Test that preparing with a familiarity value after a reset cycle sends the correct value
