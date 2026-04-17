# Lemma-Based Keyword Filter Bugfix Design

## Overview

The keyword filtering pipeline in `prepareSession` compares each keyword's `arabic` field (vocalized surface form) against exclusion lists and known-words sets that store root/base forms. Because the surface form rarely matches the root after normalization, keywords that should be excluded pass through. The LLM now returns a `lemma` field on each keyword. The fix is to use `k.lemma` (with fallback to `k.arabic`) for lookup in both Filter 1 (level-based exclusion) and Filter 2 (known keywords).

## Glossary

- **Bug_Condition (C)**: A keyword has a `lemma` field whose normalized form matches an exclusion or known-words entry, but the keyword is not filtered out because only `k.arabic` is checked.
- **Property (P)**: When a keyword's lemma matches an exclusion/known entry, the keyword is removed from the output.
- **Preservation**: Keywords without a lemma field, or whose lemma does not match any entry, must continue to be included/excluded exactly as before.
- **`isExcluded(arabic, exclusionSet)`**: Function in `src/sessions.mjs` that normalizes an Arabic string and checks membership in an exclusion set.
- **`filterKnownKeywords(keywords, knownArabicSet)`**: Function in `src/sessions.mjs` that removes keywords whose `arabic` field matches the user's known-words set.
- **`prepareSession`**: Main handler that orchestrates verse fetching, LLM invocation, and the two-stage keyword filter pipeline.
- **lemma**: The root/base form of an Arabic word returned by the LLM (e.g., `كفر` for the surface form `كَفَرُوا`).

## Bug Details

### Bug Condition

The bug manifests when a keyword object has a `lemma` field whose normalized form matches an entry in the exclusion set (Filter 1) or the known-words set (Filter 2), but the keyword is not removed because only `k.arabic` is used for comparison.

**Formal Specification:**
```
FUNCTION isBugCondition(keyword, exclusionSet, knownSet)
  INPUT: keyword of type { arabic: string, lemma?: string, ... }
         exclusionSet of type Set<string>
         knownSet of type Set<string>
  OUTPUT: boolean

  lemma := keyword.lemma
  IF lemma IS falsy THEN RETURN false

  normalizedLemmaForms := normalizeArabic(lemma)
  normalizedArabicForms := normalizeArabic(keyword.arabic)

  lemmaMatchesExclusion := ANY form IN normalizedLemmaForms WHERE exclusionSet.has(form)
  arabicMatchesExclusion := ANY form IN normalizedArabicForms WHERE exclusionSet.has(form)

  lemmaMatchesKnown := ANY form IN normalizedLemmaForms WHERE knownSet.has(form)
  arabicMatchesKnown := ANY form IN normalizedArabicForms WHERE knownSet.has(form)

  RETURN (lemmaMatchesExclusion AND NOT arabicMatchesExclusion)
      OR (lemmaMatchesKnown AND NOT arabicMatchesKnown)
END FUNCTION
```

### Examples

- Keyword `{ arabic: "كَفَرُوا", lemma: "كفر" }` with exclusion set containing `كفر`: lemma matches but `arabic` (normalized to `كفروا`) does not → keyword incorrectly passes Filter 1.
- Keyword `{ arabic: "قَالُوا", lemma: "قال" }` with known set containing `قال`: lemma matches but `arabic` (normalized to `قالوا`) does not → keyword incorrectly passes Filter 2.
- Keyword `{ arabic: "الرَّحْمَن", lemma: "رحمن" }` with exclusion set containing `رحمن`: lemma matches, `arabic` normalizes to `الرحمن`/`رحمن` — the without-article form matches, so this case already works. Not a bug condition.
- Keyword `{ arabic: "كلمة", lemma: undefined }`: no lemma → fallback to `arabic` comparison, existing behavior preserved.

## Expected Behavior

### Preservation Requirements

**Unchanged Behaviors:**
- Keywords without a `lemma` field must continue to be filtered using `k.arabic` exactly as before.
- The normalization logic (`normalizeArabic`, `stripDiacritics`, `stripDefiniteArticle`) must remain unchanged.
- `buildExclusionSet` must remain unchanged.
- The 20-keyword output cap must remain unchanged.
- Original keyword ordering must be preserved after filtering.
- Graceful degradation on DynamoDB failure must remain unchanged (return full unfiltered list capped at 20).

**Scope:**
All inputs where `keyword.lemma` is falsy are completely unaffected by this fix. The fix only changes which string is passed to the exclusion/known-set lookup — from always `k.arabic` to `k.lemma ?? k.arabic`.

## Hypothesized Root Cause

Based on the bug description, the root cause is straightforward:

1. **`isExcluded` only accepts a plain string**: The inline Filter 1 call passes `k.arabic` — it never considers `k.lemma`. The function signature `isExcluded(arabic, exclusionSet)` has no awareness of the keyword object.

2. **`filterKnownKeywords` hardcodes `k.arabic`**: Line `return keywords.filter(k => !isExcluded(k.arabic, normalizedKnown))` always uses the surface form for lookup.

Both call sites need to resolve the comparison string as `k.lemma || k.arabic` before passing it to `isExcluded`.

## Correctness Properties

Property 1: Bug Condition - Lemma-based exclusion

_For any_ keyword object where `lemma` is truthy and `normalizeArabic(lemma)` matches an entry in the exclusion set or known-words set, the fixed filtering pipeline SHALL exclude that keyword from the output.

**Validates: Requirements 2.1, 2.2**

Property 2: Preservation - Fallback and non-matching behavior

_For any_ keyword object where `lemma` is falsy, the fixed filtering pipeline SHALL produce the same filtering result as the original code (using `k.arabic` for comparison), preserving backward compatibility and all existing behavior for keywords without a lemma field.

**Validates: Requirements 2.3, 3.1, 3.2, 3.3, 3.4**

## Fix Implementation

### Changes Required

Assuming our root cause analysis is correct:

**File**: `src/sessions.mjs`

**Specific Changes**:

1. **Filter 1 inline call in `prepareSession`**: Change `k => !isExcluded(k.arabic, exclusionSet)` to `k => !isExcluded(k.lemma || k.arabic, exclusionSet)`.

2. **`filterKnownKeywords` function body**: Change `return keywords.filter(k => !isExcluded(k.arabic, normalizedKnown))` to `return keywords.filter(k => !isExcluded(k.lemma || k.arabic, normalizedKnown))`.

No signature changes are needed for `isExcluded` — it already accepts any string. The fix is two single-line changes at the call sites.

## Testing Strategy

### Validation Approach

The testing strategy follows a two-phase approach: first, surface counterexamples that demonstrate the bug on unfixed code, then verify the fix works correctly and preserves existing behavior.

### Exploratory Bug Condition Checking

**Goal**: Surface counterexamples that demonstrate the bug BEFORE implementing the fix. Confirm that keywords with a matching lemma but non-matching arabic surface form pass through the filters incorrectly.

**Test Plan**: Write tests that create keyword objects with `lemma` fields matching exclusion/known entries, and verify the unfixed code fails to filter them.

**Test Cases**:
1. **Filter 1 lemma miss**: Keyword `{ arabic: "كَفَرُوا", lemma: "كفر" }` with `كفر` in exclusion set — unfixed code will not exclude it (will fail on unfixed code)
2. **Filter 2 lemma miss**: Keyword `{ arabic: "قَالُوا", lemma: "قال" }` with `قال` in known set — unfixed code will not filter it (will fail on unfixed code)
3. **Lemma fallback**: Keyword `{ arabic: "كلمة" }` (no lemma) with `كلمة` in exclusion set — should still be excluded (should pass on unfixed code)

**Expected Counterexamples**:
- Keywords with matching lemma but non-matching arabic pass through both filters
- Root cause confirmed: call sites pass `k.arabic` instead of `k.lemma || k.arabic`

### Fix Checking

**Goal**: Verify that for all inputs where the bug condition holds, the fixed function produces the expected behavior.

**Pseudocode:**
```
FOR ALL keyword WHERE keyword.lemma IS truthy DO
  comparisonStr := keyword.lemma
  normalizedForms := normalizeArabic(comparisonStr)
  IF ANY form IN normalizedForms WHERE exclusionSet.has(form) THEN
    ASSERT keyword NOT IN filteredOutput
  END IF
END FOR
```

### Preservation Checking

**Goal**: Verify that for all inputs where the bug condition does NOT hold, the fixed function produces the same result as the original function.

**Pseudocode:**
```
FOR ALL keyword WHERE keyword.lemma IS falsy DO
  ASSERT filterFixed(keyword) = filterOriginal(keyword)
END FOR
```

**Testing Approach**: Property-based testing is recommended for preservation checking because:
- It generates many keyword objects with and without lemma fields
- It catches edge cases around falsy lemma values (empty string, null, undefined)
- It provides strong guarantees that fallback behavior is unchanged

**Test Plan**: Observe behavior on UNFIXED code first for keywords without lemma, then write property-based tests capturing that behavior.

**Test Cases**:
1. **No-lemma preservation**: Keywords without `lemma` field are filtered identically to current behavior
2. **Empty-lemma preservation**: Keywords with `lemma: ""` fall back to `arabic` comparison
3. **Ordering preservation**: Output order matches input order after filtering
4. **Cap preservation**: Output is still capped at 20 keywords

### Unit Tests

- Test `filterKnownKeywords` with keywords that have lemma matching known set
- Test `filterKnownKeywords` with keywords that have no lemma (fallback)
- Test Filter 1 inline exclusion with lemma matching exclusion set
- Test edge cases: `lemma: ""`, `lemma: null`, `lemma: undefined`

### Property-Based Tests

- Generate random keyword objects (with/without lemma) and random exclusion sets; verify that any keyword whose resolved comparison string (`lemma || arabic`) matches the set is excluded
- Generate random keyword objects without lemma fields; verify fixed code produces identical results to original logic
- Generate random keyword lists; verify output ordering and 20-keyword cap are preserved

### Integration Tests

- Test full `prepareSession` flow with mocked LLM returning keywords with lemma fields, verifying correct filtering
- Test `prepareSession` with mixed keywords (some with lemma, some without) to verify fallback
- Test graceful degradation: DynamoDB failure still returns unfiltered keywords capped at 20
