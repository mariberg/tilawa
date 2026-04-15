# UI Session Fixes — Bugfix Design

## Overview

Three UI bugs affect the session flow: (1) the recent sessions list renders every session returned by the API instead of capping at 5, (2) the loading state when the AI prepares a session is a tiny 20×20 spinner hidden inside the button — users can't tell anything is happening, and (3) both the Prep Screen and Recitation Screen headers are hardcoded to "Surah Al-Baqarah · Pages 50–54" instead of reflecting the actual surah name and pages from navigation arguments. All three fixes are localized to `entry_screen.dart`, `prep_screen.dart`, and `recitation_screen.dart` with no backend changes.

## Glossary

- **Bug_Condition (C)**: The set of conditions that trigger the three bugs — unlimited session list rendering, subtle loading indicator, and hardcoded header strings
- **Property (P)**: The desired behavior — at most 5 recent sessions shown, a prominent full-screen spinner during preparation, and dynamic headers reflecting actual session data
- **Preservation**: Existing behaviors that must remain unchanged — recent session tap logic, revisit badges, "No recent sessions" message, Recitation "Done" button spinner, hint text
- **`_recentSessions`**: The list of `RecentSession` objects fetched from the API and rendered on the Entry Screen
- **`_isPreparing`**: Boolean state in `EntryScreen` that is true while the `prepare()` API call is in flight
- **`_pages`**: The pages string (e.g. "50-54") extracted from navigation arguments in Prep/Recitation screens
- **`_surah`**: The surah ID (int) extracted from navigation arguments in Prep/Recitation screens
- **`_surahName()`**: Helper in `EntryScreen` that looks up `nameSimple` from the loaded `_surahs` list by ID

## Bug Details

### Bug Condition

The bugs manifest across three independent conditions in the session flow UI.

**Formal Specification:**
```
FUNCTION isBugCondition(input)
  INPUT: input of type UIRenderState
  OUTPUT: boolean

  // Bug 1: Recent sessions list has no limit
  IF input.screen == 'EntryScreen'
     AND input.recentSessions.length > 0
  THEN RETURN true  // all sessions rendered, no .take(5)

  // Bug 2: Loading indicator too subtle
  IF input.screen == 'EntryScreen'
     AND input.isPreparing == true
  THEN RETURN true  // only a 20x20 spinner inside button

  // Bug 3: Hardcoded header in Prep Screen
  IF input.screen == 'PrepScreen'
  THEN RETURN true  // header always "Surah Al-Baqarah · Pages 50–54"

  // Bug 3: Hardcoded header in Recitation Screen
  IF input.screen == 'RecitationScreen'
  THEN RETURN true  // header always "Surah Al-Baqarah · Pages 50–54"

  RETURN false
END FUNCTION
```

### Examples

- **Bug 1**: User has 12 recent sessions → all 12 are displayed. Expected: only the 5 most recent.
- **Bug 1 edge**: User has 3 recent sessions → all 3 displayed (correct, under limit).
- **Bug 2**: User taps "Prepare" → button text changes to a tiny 20×20 spinner inside the button. Expected: a prominent centered spinner overlay on the screen.
- **Bug 3 (Prep)**: User selects Surah An-Nisa, pages 77–81 → header still reads "Surah Al-Baqarah · Pages 50–54". Expected: "Surah An-Nisa · Pages 77–81".
- **Bug 3 (Recitation)**: Same as above on the Recitation Screen.
- **Bug 3 (pages only)**: User enters pages "10-15" with no surah → header should show "Pages 10–15" (no surah prefix).
- **Bug 3 (surah only)**: User selects Surah Al-Fatiha with no pages → header should show "Surah Al-Fatiha".

## Expected Behavior

### Preservation Requirements

**Unchanged Behaviors:**
- Tapping a recent session row must continue to populate the text field and trigger revisit/move-on logic
- The "Revisit" badge on recent session rows must continue to display
- "No recent sessions" message must still appear when the list is empty
- The recent sessions loading spinner (in the list section) must remain
- The "Prepare" button must show "Prepare" text when not loading
- The Recitation Screen "Done" button must keep its existing small spinner during submission
- The hint text "e.g. 50–54 or Surah Al-Baqarah" must remain unchanged
- Keyword cards, dot navigation, and flip interaction on Prep Screen must be unaffected
- Waveform animation on Recitation Screen must be unaffected

**Scope:**
All inputs that do NOT involve the three bug conditions should be completely unaffected by this fix. This includes:
- Mouse/tap interactions on recent session rows
- Familiarity pill selection
- Surah typeahead search behavior
- Session submission flow
- Navigation between screens

## Hypothesized Root Cause

Based on the code analysis, the root causes are straightforward:

1. **No `.take(5)` on recent sessions list**: In `entry_screen.dart`, `_recentSessions!.asMap().entries.expand(...)` iterates over the entire list. There is no `.take(5)` call to limit the displayed count.

2. **Loading indicator is only inside the button**: In `entry_screen.dart`, the `_isPreparing` state only swaps the button's child from `Text('Prepare')` to a small `CircularProgressIndicator(width: 20, height: 20)`. There is no full-screen overlay or prominent indicator.

3. **Hardcoded header strings**: In `prep_screen.dart` line ~164 and `recitation_screen.dart` line ~119, the header `Text` widget uses the literal string `'Surah Al-Baqarah · Pages 50–54'` instead of interpolating `_pages` and `_surah`. Both screens already extract `_pages` and `_surah` from navigation arguments but never use them in the header. Additionally, the surah name (`nameSimple`) is not passed via navigation arguments — only the surah ID is passed, and neither screen has access to the surahs list to look up the name.

## Correctness Properties

Property 1: Bug Condition — Recent Sessions Limited to 5

_For any_ Entry Screen render where the API returns N recent sessions (N > 5), the fixed screen SHALL display exactly 5 session rows (the first 5 from the API response, which are already sorted most-recent-first by the backend).

**Validates: Requirements 2.1**

Property 2: Bug Condition — Prominent Loading Indicator

_For any_ Entry Screen state where `_isPreparing` is true, the fixed screen SHALL display a prominent, centered `CircularProgressIndicator` that is clearly visible to the user (not confined to the button).

**Validates: Requirements 2.2**

Property 3: Bug Condition — Dynamic Header in Prep Screen

_For any_ Prep Screen render with navigation arguments containing `pages` and/or `surahName`, the fixed screen SHALL display a header string constructed from the actual values (e.g. "Surah An-Nisa · Pages 77–81") instead of the hardcoded string.

**Validates: Requirements 2.3**

Property 4: Bug Condition — Dynamic Header in Recitation Screen

_For any_ Recitation Screen render with navigation arguments containing `pages` and/or `surahName`, the fixed screen SHALL display a header string constructed from the actual values instead of the hardcoded string.

**Validates: Requirements 2.4**

Property 5: Preservation — Existing Entry Screen Behavior

_For any_ Entry Screen interaction that does NOT involve the recent sessions count, the loading indicator, or the header strings, the fixed code SHALL produce the same behavior as the original code, preserving tap handling, revisit badges, empty state messages, hint text, and familiarity selection.

**Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5, 3.8**

Property 6: Preservation — Recitation Done Button Spinner

_For any_ Recitation Screen state where `_isSubmitting` is true, the fixed code SHALL continue to show the existing small 20×20 spinner inside the "Done" button, unchanged from the original behavior.

**Validates: Requirements 3.6**

Property 7: Preservation — Page-Only Session Header

_For any_ session started with pages but no surah, the Prep and Recitation Screen headers SHALL display only the pages (e.g. "Pages 50–54") without a surah prefix.

**Validates: Requirements 3.7**

## Fix Implementation

### Changes Required

**File**: `lib/screens/entry_screen.dart`

**Bug 1 — Limit recent sessions to 5:**
1. In the `build()` method, where `_recentSessions!.asMap().entries.expand(...)` is called, add `.take(5)` before `.asMap()` to limit the rendered list to 5 items.

**Bug 2 — Prominent loading indicator:**
2. Wrap the `Scaffold` body content in a `Stack`.
3. When `_isPreparing` is true, overlay a centered `CircularProgressIndicator` on top of the existing content (semi-transparent background optional for visual clarity).
4. Keep the button disabled during `_isPreparing` (already the case) but remove the small spinner from inside the button — show "Prepare" text always, or keep it disabled with text. The prominent overlay is the primary indicator.

**Bug 3 — Pass surah name via navigation arguments:**
5. In the `_prepare()` method, when pushing to `/prep`, add `'surahName': _selectedSurah?.nameSimple` to the arguments map. This passes the resolved surah name string so downstream screens don't need the full surahs list.

---

**File**: `lib/screens/prep_screen.dart`

**Bug 3 — Dynamic header:**
1. Add a `String? _surahName` field and extract it from `args['surahName']` in `didChangeDependencies`.
2. Replace the hardcoded `'Surah Al-Baqarah · Pages 50–54'` with a computed string:
   - If both surah name and pages exist: `'Surah $_surahName · Pages $_pages'`
   - If only surah name: `'Surah $_surahName'`
   - If only pages: `'Pages $_pages'`
   - Fallback: `'Session'`
3. When navigating to `/recitation` in `_completeSession()`, forward `'surahName': _surahName` in the arguments map.

---

**File**: `lib/screens/recitation_screen.dart`

**Bug 3 — Dynamic header:**
1. Add a `String? _surahName` field and extract it from `args['surahName']` in `didChangeDependencies`.
2. Replace the hardcoded `'Surah Al-Baqarah · Pages 50–54'` with the same computed string logic as the Prep Screen.

## Testing Strategy

### Validation Approach

The testing strategy follows a two-phase approach: first, surface counterexamples that demonstrate the bugs on unfixed code, then verify the fixes work correctly and preserve existing behavior.

### Exploratory Bug Condition Checking

**Goal**: Surface counterexamples that demonstrate the bugs BEFORE implementing the fix. Confirm or refute the root cause analysis.

**Test Plan**: Write widget tests that render each screen with controlled arguments and assert on the rendered output. Run on UNFIXED code to observe failures.

**Test Cases**:
1. **Recent Sessions Overflow**: Render EntryScreen with 10 mock sessions → assert only 5 rows rendered (will fail on unfixed code — all 10 shown)
2. **Loading Indicator Visibility**: Render EntryScreen in `_isPreparing = true` state → assert a prominent centered spinner exists (will fail on unfixed code — only button spinner)
3. **Prep Screen Header**: Render PrepScreen with args `{surahName: 'An-Nisa', pages: '77-81'}` → assert header contains "Surah An-Nisa · Pages 77–81" (will fail on unfixed code — hardcoded string)
4. **Recitation Screen Header**: Same as above for RecitationScreen (will fail on unfixed code)

**Expected Counterexamples**:
- All sessions rendered without limit
- No full-screen spinner found in widget tree
- Header text always equals "Surah Al-Baqarah · Pages 50–54" regardless of arguments

### Fix Checking

**Goal**: Verify that for all inputs where the bug condition holds, the fixed code produces the expected behavior.

**Pseudocode:**
```
FOR ALL input WHERE isBugCondition(input) DO
  result := renderScreen_fixed(input)
  ASSERT expectedBehavior(result)
END FOR
```

### Preservation Checking

**Goal**: Verify that for all inputs where the bug condition does NOT hold, the fixed code produces the same result as the original code.

**Pseudocode:**
```
FOR ALL input WHERE NOT isBugCondition(input) DO
  ASSERT renderScreen_original(input) = renderScreen_fixed(input)
END FOR
```

**Testing Approach**: Property-based testing is recommended for preservation checking because:
- It generates many test cases automatically across the input domain
- It catches edge cases that manual unit tests might miss
- It provides strong guarantees that behavior is unchanged for all non-buggy inputs

**Test Plan**: Observe behavior on UNFIXED code first for non-bug interactions, then write tests capturing that behavior.

**Test Cases**:
1. **Recent Session Tap Preservation**: Verify tapping a session row still populates the text field correctly after the `.take(5)` change
2. **Empty State Preservation**: Verify "No recent sessions" still displays when list is empty
3. **Button Text Preservation**: Verify "Prepare" text shows when not loading
4. **Recitation Done Spinner Preservation**: Verify the small spinner still appears in the Done button during submission

### Unit Tests

- Test that `.take(5)` correctly limits a list of N > 5 sessions
- Test header string construction with various combinations of surahName and pages (both, surah only, pages only, neither)
- Test that `_surahName` is correctly extracted from navigation arguments

### Property-Based Tests

- Generate random lists of RecentSession (length 0–20) and verify at most 5 are rendered
- Generate random surahName/pages combinations and verify header string is correctly formatted
- Generate random non-bug interactions and verify preservation of behavior

### Integration Tests

- Test full flow: select surah → prepare → verify Prep Screen header → complete → verify Recitation Screen header
- Test page-only flow: enter pages → prepare → verify headers show pages without surah prefix
- Test that the loading overlay appears and disappears correctly during the prepare API call
