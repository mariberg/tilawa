# Surah Verse Range Fix — Bugfix Design

## Overview

The `resolveChapterAndVerse` function in `src/sessions.mjs` hardcodes `verseNumber` to `1` and sets both `startVerseKey` and `endVerseKey` to `{surah}:1` when a surah number is provided. This produces a collapsed verse range that causes downstream syncs (Reading Sessions API and Activity Days API) to report incorrect data. The fix will use the existing `fetchVersesForChapter` function to retrieve the actual verses for the surah and derive the last verse number, setting `endVerseKey` to `{surah}:{lastVerse}` and `verseNumber` to the last verse number.

## Glossary

- **Bug_Condition (C)**: The condition that triggers the bug — when `resolveChapterAndVerse` is called with a non-null `surah` parameter (and no `pages`), causing hardcoded verse data
- **Property (P)**: The desired behavior — `verseNumber` equals the last verse of the surah, and `endVerseKey` equals `{surah}:{lastVerse}`
- **Preservation**: Existing page-based resolution logic, sync behavior for page-based sessions, and error handling must remain unchanged
- **resolveChapterAndVerse**: The function in `src/sessions.mjs` that converts session parameters (surah or pages) into chapter/verse numbers and verse key ranges for API syncs
- **fetchVersesForChapter**: The existing function in `src/sessions.mjs` that fetches all verses for a given chapter number from the Quran API
- **syncReadingSession**: Fire-and-forget function that posts `chapterNumber` and `verseNumber` to the Reading Sessions API
- **syncActivityDay**: Fire-and-forget function that posts a verse range to the Activity Days API

## Bug Details

### Bug Condition

The bug manifests when `resolveChapterAndVerse` is called with a non-null `surah` parameter. The function immediately returns hardcoded values without fetching any verse data, setting `verseNumber` to `1` and `endVerseKey` to `{surah}:1` (identical to `startVerseKey`).

**Formal Specification:**
```
FUNCTION isBugCondition(input)
  INPUT: input of type { surah: number | string | null, pages: string | null }
  OUTPUT: boolean

  RETURN input.surah IS NOT NULL
END FUNCTION
```

### Examples

- Surah 69 (Al-Haqqah, 52 verses): Expected `endVerseKey = "69:52"`, `verseNumber = 52`. Actual: `endVerseKey = "69:1"`, `verseNumber = 1`.
- Surah 2 (Al-Baqarah, 286 verses): Expected `endVerseKey = "2:286"`, `verseNumber = 286`. Actual: `endVerseKey = "2:1"`, `verseNumber = 1`.
- Surah 108 (Al-Kawthar, 3 verses): Expected `endVerseKey = "108:3"`, `verseNumber = 3`. Actual: `endVerseKey = "108:1"`, `verseNumber = 1`.
- Surah 1 (Al-Fatihah, 7 verses): Expected `endVerseKey = "1:7"`, `verseNumber = 7`. Actual: `endVerseKey = "1:1"`, `verseNumber = 1`.

## Expected Behavior

### Preservation Requirements

**Unchanged Behaviors:**
- Page-based session resolution (`pages` parameter path) must continue to fetch verses for first/last pages and derive verse keys and chapter/verse numbers from actual page data
- `syncReadingSession` and `syncActivityDay` function signatures and internal logic must remain unchanged
- `startVerseKey` for surah-based sessions must remain `{surah}:1` (surahs always start at verse 1)
- Error handling for invalid page ranges, empty API responses on page fetches, and malformed verse keys must remain unchanged

**Scope:**
All inputs where `surah` is `null` (i.e., page-based sessions) should be completely unaffected by this fix. This includes:
- Sessions created with a `pages` parameter
- All existing error handling paths in the page-based branch
- All downstream sync calls originating from page-based sessions

## Hypothesized Root Cause

Based on the bug description, the most likely issue is:

1. **Missing API Call in Surah Branch**: The surah branch of `resolveChapterAndVerse` was implemented as a shortcut that skips the verse-fetching step entirely. Unlike the page-based branch (which calls `fetchVersesForPage` to get actual verse data), the surah branch hardcodes `verseNumber: 1` and constructs verse keys without querying the API. This was likely an oversight or placeholder implementation.

2. **Incorrect Assumption About Verse Range**: The original code assumes that only the start verse key matters, or that the caller would handle the end verse separately. In reality, both `syncReadingSession` (which needs the last verse number) and `syncActivityDay` (which needs the full range) depend on accurate values from `resolveChapterAndVerse`.

## Correctness Properties

Property 1: Bug Condition — Surah-based sessions resolve correct last verse

_For any_ input where `surah` is not null (isBugCondition returns true), the fixed `resolveChapterAndVerse` function SHALL call `fetchVersesForChapter(surah)`, set `verseNumber` to the verse number of the last verse returned, and set `endVerseKey` to the verse key of the last verse returned (e.g., `"69:52"` for surah 69).

**Validates: Requirements 2.1, 2.2**

Property 2: Preservation — Page-based sessions produce identical results

_For any_ input where `surah` is null and `pages` is provided (isBugCondition returns false), the fixed `resolveChapterAndVerse` function SHALL produce exactly the same `chapterNumber`, `verseNumber`, `startVerseKey`, and `endVerseKey` as the original function, preserving all page-based resolution logic.

**Validates: Requirements 3.1, 3.2, 3.3**

## Fix Implementation

### Changes Required

Assuming our root cause analysis is correct:

**File**: `src/sessions.mjs`

**Function**: `resolveChapterAndVerse`

**Specific Changes**:
1. **Add `fetchVersesForChapter` call**: In the `if (surah != null)` branch, call `await fetchVersesForChapter(Number(surah))` to retrieve the actual verses for the surah.

2. **Add empty-response guard**: After fetching, check that the returned array is non-empty. If empty, throw an error consistent with the page-based branch's error handling (e.g., `throw new Error("No verses returned for chapter {surah}")`).

3. **Derive last verse data**: Extract the last element of the returned verses array. Parse its `verseKey` (e.g., `"69:52"`) to get the last verse number.

4. **Set `endVerseKey` correctly**: Set `endVerseKey` to the last verse's `verseKey` instead of `startVerseKey`.

5. **Set `verseNumber` correctly**: Set `verseNumber` to the parsed last verse number instead of hardcoded `1`.

## Testing Strategy

### Validation Approach

The testing strategy follows a two-phase approach: first, surface counterexamples that demonstrate the bug on unfixed code, then verify the fix works correctly and preserves existing behavior.

### Exploratory Bug Condition Checking

**Goal**: Surface counterexamples that demonstrate the bug BEFORE implementing the fix. Confirm or refute the root cause analysis. If we refute, we will need to re-hypothesize.

**Test Plan**: Write unit tests that call `resolveChapterAndVerse` with various surah numbers (mocking `fetchVersesForChapter` to return known verse arrays) and assert that `endVerseKey` and `verseNumber` reflect the last verse. Run these tests on the UNFIXED code to observe failures.

**Test Cases**:
1. **Short Surah Test**: Call with `surah=108` (3 verses), expect `endVerseKey="108:3"`, `verseNumber=3` (will fail on unfixed code)
2. **Long Surah Test**: Call with `surah=2` (286 verses), expect `endVerseKey="2:286"`, `verseNumber=286` (will fail on unfixed code)
3. **Medium Surah Test**: Call with `surah=69` (52 verses), expect `endVerseKey="69:52"`, `verseNumber=52` (will fail on unfixed code)
4. **Empty Response Test**: Call with a surah where API returns no verses, expect an error to be thrown (may fail on unfixed code — currently returns hardcoded values instead of throwing)

**Expected Counterexamples**:
- `verseNumber` is always `1` regardless of surah
- `endVerseKey` is always `{surah}:1`, identical to `startVerseKey`
- Possible cause: the surah branch never calls `fetchVersesForChapter`

### Fix Checking

**Goal**: Verify that for all inputs where the bug condition holds, the fixed function produces the expected behavior.

**Pseudocode:**
```
FOR ALL input WHERE isBugCondition(input) DO
  result := resolveChapterAndVerse_fixed(input.surah, null)
  verses := fetchVersesForChapter(input.surah)
  lastVerse := verses[verses.length - 1]
  ASSERT result.endVerseKey = lastVerse.verseKey
  ASSERT result.verseNumber = parseVerseNumber(lastVerse.verseKey)
  ASSERT result.startVerseKey = "{input.surah}:1"
  ASSERT result.chapterNumber = input.surah
END FOR
```

### Preservation Checking

**Goal**: Verify that for all inputs where the bug condition does NOT hold, the fixed function produces the same result as the original function.

**Pseudocode:**
```
FOR ALL input WHERE NOT isBugCondition(input) DO
  ASSERT resolveChapterAndVerse_original(null, input.pages) = resolveChapterAndVerse_fixed(null, input.pages)
END FOR
```

**Testing Approach**: Property-based testing is recommended for preservation checking because:
- It generates many test cases automatically across the input domain
- It catches edge cases that manual unit tests might miss
- It provides strong guarantees that behavior is unchanged for all non-buggy inputs

**Test Plan**: Observe behavior on UNFIXED code first for page-based inputs, then write property-based tests capturing that behavior.

**Test Cases**:
1. **Single Page Preservation**: Verify `resolveChapterAndVerse(null, "50")` produces identical results before and after fix
2. **Page Range Preservation**: Verify `resolveChapterAndVerse(null, "50-54")` produces identical results before and after fix
3. **Error Handling Preservation**: Verify that invalid page inputs continue to throw the same errors

### Unit Tests

- Test `resolveChapterAndVerse` with various surah numbers and mocked `fetchVersesForChapter` responses
- Test edge cases: surah with 1 verse (hypothetical), surah with empty API response
- Test that page-based path still works correctly with mocked `fetchVersesForPage`

### Property-Based Tests

- Generate random surah numbers (1–114) with mocked verse arrays and verify `endVerseKey` and `verseNumber` match the last verse
- Generate random page range strings and verify the page-based path produces consistent results before and after fix
- Generate random verse arrays of varying lengths and verify the last verse is always correctly extracted

### Integration Tests

- Test full `createSession` flow with a surah number and verify `syncReadingSession` receives the correct `verseNumber`
- Test full `createSession` flow with a surah number and verify `syncActivityDay` receives the correct verse range
- Test full `createSession` flow with page numbers and verify sync calls are unchanged
