# Page Number Validation Bugfix Design

## Overview

The app's page parsing logic (`parsePageRange()` in `page_utils.dart` and `_parsePages()` in `entry_screen.dart`) accepts any positive integer as a page number without checking Quran bounds (1–604). This allows users to create sessions with invalid page numbers (e.g. 700, 0, or reversed ranges like 100-50), which get sent to the backend unchecked. The fix adds bounds validation to `parsePageRange()` so that all page inputs are validated at the utility layer, and updates `_parsePages()` to surface meaningful error messages to the user.

## Glossary

- **Bug_Condition (C)**: The condition that triggers the bug — when a page number outside 1–604 or a reversed range is accepted without error
- **Property (P)**: The desired behavior — page inputs outside valid bounds are rejected with a descriptive `FormatException`
- **Preservation**: Valid page inputs (1–604, start ≤ end) and surah name inputs must continue to work exactly as before
- **parsePageRange()**: The function in `lib/utils/page_utils.dart` that parses a page string into `(start, end, span)` — currently has no bounds checking
- **_parsePages()**: The private method in `lib/screens/entry_screen.dart` that validates format and delegates to page parsing — currently only checks format, not bounds
- **MAX_PAGE**: 604, the total number of pages in the Quran

## Bug Details

### Bug Condition

The bug manifests when a user enters page numbers that are syntactically valid integers but semantically out of bounds for the Quran (not in 1–604), or when start > end in a range. Both `parsePageRange()` and `_parsePages()` only check format (digits, dash) but never validate the numeric values.

**Formal Specification:**
```
FUNCTION isBugCondition(input)
  INPUT: input of type String (page input from user)
  OUTPUT: boolean

  parsed := parsePageRange(input)
  IF parsed IS NULL THEN RETURN FALSE  // not a page input at all

  RETURN parsed.start < 1
         OR parsed.end > 604
         OR parsed.start > parsed.end
END FUNCTION
```

### Examples

- User enters "700" → accepted, sent to backend (expected: rejected with "Page numbers must be between 1 and 604")
- User enters "600-610" → accepted, sent to backend (expected: rejected with "Page numbers must be between 1 and 604")
- User enters "0" → accepted, sent to backend (expected: rejected with "Page numbers must be between 1 and 604")
- User enters "100-50" → accepted, sent to backend (expected: rejected with "Start page must not exceed end page")

## Expected Behavior

### Preservation Requirements

**Unchanged Behaviors:**
- Valid single page numbers (1–604) must continue to parse and return correct `(start, end, span)` tuples
- Valid page ranges within 1–604 where start ≤ end must continue to work
- Surah name input path must be completely unaffected (it bypasses page parsing)
- Recent session auto-fill via `nextPageRange()` and `formatPageRange()` must continue to work
- Mouse/keyboard interaction with the text field and typeahead must remain unchanged

**Scope:**
All inputs that produce page numbers within 1–604 with start ≤ end should be completely unaffected by this fix. This includes:
- Single pages like "1", "50", "604"
- Ranges like "1-10", "50-54", "600-604"
- Surah name inputs like "Al-Baqarah"
- Non-page inputs (empty string, text-only)

## Hypothesized Root Cause

Based on the bug description, the most likely issue is:

1. **Missing Bounds Validation in `parsePageRange()`**: The function parses digits and dashes correctly but never checks if the resulting integers fall within 1–604. It returns any parsed integers as-is.

2. **Missing Bounds Validation in `_parsePages()`**: This method checks format (starts with digit, matches single or range pattern) but never validates the numeric values. It delegates format checking to regex but has no semantic validation.

3. **No Validation Layer Before API Call**: `SessionService.prepare()` receives the pages string and sends it directly to the backend. There is no intermediate validation step.

The root cause is straightforward: bounds checking was never implemented. The fix belongs primarily in `parsePageRange()` (the shared utility) so all callers benefit, with `_parsePages()` catching the `FormatException` to display user-facing errors.

## Correctness Properties

Property 1: Bug Condition — Out-of-bounds page numbers are rejected

_For any_ page input string where the parsed page numbers fall outside 1–604 or where start > end, the fixed `parsePageRange()` function SHALL throw a `FormatException` with a descriptive message, preventing the invalid input from being sent to the backend.

**Validates: Requirements 2.1, 2.2, 2.3, 2.4**

Property 2: Preservation — Valid page inputs continue to parse correctly

_For any_ page input string where the parsed page numbers are within 1–604 and start ≤ end, the fixed `parsePageRange()` function SHALL return the same `(start, end, span)` tuple as the original function, preserving all existing valid behavior.

**Validates: Requirements 3.1, 3.2, 3.3, 3.4**

## Fix Implementation

### Changes Required

Assuming our root cause analysis is correct:

**File**: `lib/utils/page_utils.dart`

**Function**: `parsePageRange()`

**Specific Changes**:
1. **Add a constant**: Define `const maxQuranPage = 604` at the top of the file for clarity and reuse
2. **Add bounds check after parsing range**: After extracting `start` and `end` from the range regex, validate `start >= 1`, `end <= 604`, and `start <= end`. Throw `FormatException` with appropriate message if violated.
3. **Add bounds check after parsing single page**: After extracting the single page number, validate `page >= 1` and `page <= 604`. Throw `FormatException` if violated.
4. **Order of checks**: Check bounds (1–604) first, then check start ≤ end, so error messages are specific.

**File**: `lib/screens/entry_screen.dart`

**Function**: `_parsePages()`

**Specific Changes**:
5. **No structural changes needed**: `_parsePages()` already catches `FormatException` in the `_prepare()` method and displays `e.message` to the user. The new `FormatException`s thrown by `parsePageRange()` will propagate naturally. However, `_parsePages()` currently does its own regex validation before calling `parsePageRange()`. We should refactor `_parsePages()` to delegate validation entirely to `parsePageRange()` to avoid duplicated logic.

## Testing Strategy

### Validation Approach

The testing strategy follows a two-phase approach: first, surface counterexamples that demonstrate the bug on unfixed code, then verify the fix works correctly and preserves existing behavior.

### Exploratory Bug Condition Checking

**Goal**: Surface counterexamples that demonstrate the bug BEFORE implementing the fix. Confirm that `parsePageRange()` currently accepts out-of-bounds values.

**Test Plan**: Write tests that call `parsePageRange()` with out-of-bounds inputs and assert that it currently returns a result (no error). Run these on the UNFIXED code to confirm the bug exists.

**Test Cases**:
1. **Over Max Test**: Call `parsePageRange("700")` — currently returns `(700, 700, 1)` (will fail on unfixed code after fix)
2. **Range Over Max Test**: Call `parsePageRange("600-610")` — currently returns `(600, 610, 11)` (will fail on unfixed code after fix)
3. **Zero Page Test**: Call `parsePageRange("0")` — currently returns `(0, 0, 1)` (will fail on unfixed code after fix)
4. **Reversed Range Test**: Call `parsePageRange("100-50")` — currently returns `(100, 50, -49)` (will fail on unfixed code after fix)

**Expected Counterexamples**:
- `parsePageRange("700")` returns a valid tuple instead of throwing
- `parsePageRange("0")` returns a valid tuple instead of throwing
- Possible cause: no bounds checking exists in the function

### Fix Checking

**Goal**: Verify that for all inputs where the bug condition holds, the fixed function rejects them with a `FormatException`.

**Pseudocode:**
```
FOR ALL input WHERE isBugCondition(input) DO
  result := parsePageRange_fixed(input)
  ASSERT result THROWS FormatException
  ASSERT exception.message CONTAINS appropriate bounds info
END FOR
```

### Preservation Checking

**Goal**: Verify that for all inputs where the bug condition does NOT hold, the fixed function produces the same result as the original function.

**Pseudocode:**
```
FOR ALL input WHERE NOT isBugCondition(input) DO
  ASSERT parsePageRange_original(input) = parsePageRange_fixed(input)
END FOR
```

**Testing Approach**: Property-based testing is recommended for preservation checking because:
- It generates many random valid page numbers/ranges within 1–604 automatically
- It catches edge cases at boundaries (1, 604, adjacent values)
- It provides strong guarantees that valid behavior is unchanged

**Test Plan**: Observe behavior on UNFIXED code first for valid inputs, then write property-based tests capturing that behavior.

**Test Cases**:
1. **Valid Single Page Preservation**: Generate random pages in [1, 604], verify `parsePageRange` returns correct `(start: page, end: page, span: 1)`
2. **Valid Range Preservation**: Generate random `(start, end)` pairs where `1 ≤ start ≤ end ≤ 604`, verify `parsePageRange` returns correct tuple
3. **Non-Page Input Preservation**: Verify that non-numeric inputs (surah names, empty strings) still return `null`

### Unit Tests

- Test `parsePageRange("0")` throws `FormatException`
- Test `parsePageRange("605")` throws `FormatException`
- Test `parsePageRange("700")` throws `FormatException`
- Test `parsePageRange("100-50")` throws `FormatException`
- Test `parsePageRange("600-610")` throws `FormatException`
- Test `parsePageRange("1")` returns `(1, 1, 1)`
- Test `parsePageRange("604")` returns `(604, 604, 1)`
- Test `parsePageRange("50-54")` returns `(50, 54, 5)`
- Test `_parsePages` integration with bounds validation

### Property-Based Tests

- Generate random integers outside [1, 604] and verify `parsePageRange` throws for single pages
- Generate random `(start, end)` pairs where start > end and verify `parsePageRange` throws
- Generate random valid pages in [1, 604] and verify `parsePageRange` returns correct tuples unchanged
- Generate random valid ranges and verify preservation of `(start, end, span)` computation

### Integration Tests

- Test full `_prepare()` flow with out-of-bounds page input shows error in UI
- Test full `_prepare()` flow with valid page input proceeds to session preparation
- Test that `nextPageRange()` output fed back into `parsePageRange()` remains valid when within bounds
