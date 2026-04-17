# Bugfix Requirements Document

## Introduction

The keyword filtering logic in `prepareSession` compares each keyword's `arabic` field (the fully vocalized, conjugated surface form from the Quran text) against the word lists (`high_frequency_words.json`, `common_Quranic_words.json`) and the user's known-words set. These lists store words in their root/base form. Because the surface form rarely matches the root form after only stripping diacritics and the definite article, many keywords that should be filtered out pass through undetected.

The LLM prompt has already been updated to return a `lemma` (root/base form) on each keyword object. The filtering functions need to compare using `lemma` instead of (or in addition to) `arabic`.

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN a keyword has `arabic: "كَفَرُوا"` (vocalized conjugated form) and the exclusion list contains `كفروا` or `كفر` (root form) THEN the system fails to filter the keyword because `isExcluded` compares the normalized `arabic` field, which after stripping diacritics yields `كفروا` — this matches `كفروا` but not the root `كفر`, so root-only entries are missed.

1.2 WHEN a keyword has a `lemma` field (e.g., `lemma: "كفر"`) that matches an entry in the level-based exclusion set THEN the system ignores the `lemma` field entirely and only checks `k.arabic` against the exclusion set in the Filter 1 step (`prepareSession`).

1.3 WHEN a keyword has a `lemma` field that matches an entry in the user's known-words set THEN the system ignores the `lemma` field and only checks `k.arabic` in `filterKnownKeywords` (Filter 2), so the keyword is not removed even though the user already knows its root.

### Expected Behavior (Correct)

2.1 WHEN a keyword object has a `lemma` field THEN the system SHALL use `k.lemma` (after normalization) for comparison against the level-based exclusion set in Filter 1, so that root-form matches are correctly detected.

2.2 WHEN a keyword object has a `lemma` field THEN the system SHALL use `k.lemma` (after normalization) for comparison against the user's known-words set in `filterKnownKeywords` (Filter 2), so that root-form matches are correctly detected.

2.3 WHEN a keyword object does not have a `lemma` field (or `lemma` is falsy) THEN the system SHALL fall back to using `k.arabic` for comparison, preserving backward compatibility.

### Unchanged Behavior (Regression Prevention)

3.1 WHEN a keyword's `lemma` does not match any entry in the exclusion set or known-words set THEN the system SHALL CONTINUE TO include that keyword in the output.

3.2 WHEN the DynamoDB query for known keywords fails THEN the system SHALL CONTINUE TO return the full unfiltered keyword list (capped at 20), as it does today (graceful degradation).

3.3 WHEN keywords are filtered THEN the system SHALL CONTINUE TO preserve the original ordering of the remaining keywords.

3.4 WHEN the final keyword list is produced THEN the system SHALL CONTINUE TO cap the output at 20 keywords.
