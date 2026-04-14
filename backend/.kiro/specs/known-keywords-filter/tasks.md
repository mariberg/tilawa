# Implementation Plan: Known Keywords Filter

## Overview

Add a filtering step to `prepareSession()` in `src/sessions.mjs` that queries the user's known keywords from DynamoDB and removes them from the LLM-generated keyword list before returning it. The filter is a pure function for testability, and the system degrades gracefully if the DB query fails.

## Tasks

- [x] 1. Implement the pure filter function and integrate into prepareSession
  - [x] 1.1 Add `filterKnownKeywords` pure function to `src/sessions.mjs`
    - Implement `filterKnownKeywords(keywords, knownArabicSet)` that filters out keywords whose `arabic` field is in the provided Set
    - The function must preserve original ordering of the input array
    - Export the function for testing
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 3.1_

  - [x] 1.2 Add known keywords DynamoDB query to `prepareSession()`
    - After extracting `userId`, query `queryItems(`USER#${userId}`, "KEYWORD#")` to fetch known keywords
    - Build a `Set<string>` from the `arabic` field of each returned item
    - Wrap the query in try/catch: on failure, log via `console.error` and use an empty Set
    - _Requirements: 1.1, 1.2, 1.3_

  - [x] 1.3 Wire filter into the response path in `prepareSession()`
    - After parsing the LLM response, call `filterKnownKeywords()` on the keywords array with the known set
    - Apply `.slice(0, 20)` after filtering to preserve the existing cap
    - Return the filtered keywords in the response body
    - _Requirements: 2.3, 3.2, 3.3_

  - [x]* 1.4 Write property test: Filter correctness (Property 1)
    - **Property 1: Filter correctness — known keywords are removed, unknowns preserved in order**
    - Generate random arrays of keyword objects and random Sets of known Arabic strings
    - Verify the output is the exact subsequence of keywords whose `arabic` field is not in the known set, in original order
    - File: `tests/property/keywords-filter.property.test.mjs`
    - **Validates: Requirements 2.1, 2.2, 2.3, 2.4, 3.1**

  - [x]* 1.5 Write property test: Output cap (Property 2)
    - **Property 2: Output cap — at most 20 keywords returned**
    - Generate keyword arrays of varying lengths (0–50) and random known sets
    - Verify the final output length is always ≤ 20
    - File: `tests/property/keywords-filter.property.test.mjs`
    - **Validates: Requirements 3.2, 3.3**

- [x] 2. Checkpoint - Verify core implementation
  - Ensure all tests pass, ask the user if questions arise.

- [x] 3. Graceful degradation and unit tests
  - [x]* 3.1 Write property test: Graceful degradation (Property 3)
    - **Property 3: Graceful degradation — DB failure returns full keyword list**
    - Generate random keyword arrays, mock `queryItems` to throw
    - Verify output matches unfiltered list capped at 20
    - File: `tests/property/keywords-filter.property.test.mjs`
    - **Validates: Requirements 1.3**

  - [x]* 3.2 Write unit tests for known keywords filter
    - Test that `prepareSession` queries DynamoDB with correct PK (`USER#{userId}`) and SK prefix (`KEYWORD#`)
    - Test that `createSession` still writes `KEYWORD#{arabic}` items for known keywords (no regression)
    - Test filter with empty known set returns all keywords
    - Test filter with all keywords known returns empty array
    - Test filter with partially overlapping known set
    - File: `tests/unit/keywords-filter.test.mjs`
    - _Requirements: 1.1, 1.2, 2.1, 2.4, 4.1, 4.2_

- [x] 4. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- The only file modified for production code is `src/sessions.mjs` — no new routes, files, or infrastructure changes
- `queryItems` in `src/db.mjs` already supports the `begins_with` query pattern needed
- `createSession` is not modified — requirement 4.1 and 4.2 are satisfied by design
- Property tests use `fast-check` with `vitest` (both already in devDependencies)
