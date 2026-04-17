# Implementation Plan: Arabic Level Settings

## Overview

Add a user settings system that persists Arabic proficiency level in DynamoDB. Create a new `src/settings.mjs` module with `saveSettings` and `getSettings`, wire two new routes (`PUT /settings`, `GET /settings`) into the router, and modify `prepareSession` to fetch the stored level instead of relying on the per-request `familiarity` field.

## Tasks

- [x] 1. Create settings module with save and get functions
  - [x] 1.1 Create `src/settings.mjs` with `saveSettings(body, userId)`
    - Validate `body.arabicLevel` is one of `"new"`, `"somewhat_familiar"`, `"well_known"`
    - Return 400 with descriptive message if missing or invalid
    - Call `putItem` with `PK: USER#<userId>`, `SK: SETTINGS`, `arabicLevel`, and `updatedAt` (ISO 8601)
    - Return `{ statusCode: 200, body: { arabicLevel } }`
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

  - [x] 1.2 Add `getSettings(userId)` to `src/settings.mjs`
    - Call `getItem(`USER#${userId}`, "SETTINGS")` to fetch the settings record
    - If no record exists, return `{ statusCode: 200, body: { arabicLevel: null } }`
    - If record exists, return `{ statusCode: 200, body: { arabicLevel: record.arabicLevel } }`
    - _Requirements: 2.1, 2.2_

  - [x]* 1.3 Write property test: Settings round-trip (Property 1)
    - **Property 1: Settings round-trip**
    - Generate random valid `arabicLevel` values, save then get, verify round-trip returns the last saved value
    - Use in-memory Map to mock DB layer
    - File: `tests/property/settings.property.test.mjs`
    - **Validates: Requirements 1.1, 1.4, 1.5, 2.1**

  - [x]* 1.4 Write property test: Invalid arabicLevel rejected (Property 2)
    - **Property 2: Invalid arabicLevel values are rejected**
    - Generate arbitrary strings not in the valid set (including empty, null, undefined), verify 400 and no state change
    - File: `tests/property/settings.property.test.mjs`
    - **Validates: Requirements 1.2, 1.3**

- [x] 2. Wire settings routes into the router
  - [x] 2.1 Add `PUT /settings` and `GET /settings` routes to `src/router.mjs`
    - Import `saveSettings` and `getSettings` from `./settings.mjs`
    - Add `PUT /settings` branch that calls `saveSettings(JSON.parse(event.body || "{}"), userId)`
    - Add `GET /settings` branch that calls `getSettings(userId)`
    - _Requirements: 4.1, 4.2_

  - [x]* 2.2 Write property test: Router dispatches settings requests (Property 4)
    - **Property 4: Router dispatches settings requests correctly**
    - Generate PUT/GET events for `/settings`, verify router output matches direct handler call
    - File: `tests/property/settings.property.test.mjs`
    - **Validates: Requirements 4.1, 4.2**

- [x] 3. Checkpoint - Verify settings module and routing
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 4. Modify prepareSession to use stored Arabic level
  - [ ] 4.1 Update `prepareSession` in `src/sessions.mjs` to fetch stored settings
    - Import `getItem` from `./db.mjs`
    - At the start of `prepareSession`, call `getItem(`USER#${userId}`, "SETTINGS")` to fetch stored settings
    - If stored `arabicLevel` exists, use it as `familiarity`, ignoring `body.familiarity`
    - If no stored level and no `body.familiarity`, return 400 with descriptive message
    - If no stored level but `body.familiarity` is present, use `body.familiarity` as fallback
    - Remove the existing early 400 check for missing `familiarity` and replace with the new logic
    - _Requirements: 3.1, 3.2, 3.3, 3.4_

  - [ ]* 4.2 Write property test: Stored level takes precedence (Property 3)
    - **Property 3: Stored arabicLevel takes precedence over request-body familiarity**
    - Generate a stored level and a different body familiarity, verify stored level wins
    - File: `tests/property/settings.property.test.mjs`
    - **Validates: Requirements 3.2, 3.4**

- [x] 5. Unit tests for edge cases
  - [x]* 5.1 Write unit tests for settings module
    - Test `getSettings` returns `{ arabicLevel: null }` for user with no settings record
    - Test `saveSettings` returns 400 for each invalid value: `undefined`, `""`, `"invalid_string"`
    - Test `prepareSession` returns 400 when no stored setting and no `familiarity` in body
    - Test router returns 404 for unrelated routes (regression)
    - File: `tests/unit/settings.test.mjs`
    - _Requirements: 1.2, 1.3, 2.2, 3.3_

- [x] 6. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Property tests use `fast-check` with `vitest` (both already in devDependencies)
- DB layer (`src/db.mjs`) already has `getItem` and `putItem` — no changes needed
- No infrastructure changes required — existing DynamoDB table and Lambda support this
