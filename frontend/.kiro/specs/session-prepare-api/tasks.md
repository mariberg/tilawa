# Implementation Plan: Session Prepare API

## Overview

Incrementally build the session prepare API integration. Start with environment configuration and package dependencies, then data models, then the service layer, wiring everything together with validation, error handling, and tests.

## Tasks

- [x] 1. Add package dependencies and environment configuration
  - [x] 1.1 Add `flutter_dotenv` to `pubspec.yaml` under dependencies
    - Run `flutter pub get` to install
    - _Requirements: 6.1_

  - [x] 1.2 Create `.env.example` at the project root with `BASE_URL=https://your-api-url.com`
    - _Requirements: 1.2_

  - [x] 1.3 Create `.env` at the project root with `BASE_URL=https://your-api-url.com`
    - _Requirements: 1.1_

  - [x] 1.4 Add `.env` entry to `.gitignore`
    - _Requirements: 1.3_

  - [x] 1.5 Update `lib/main.dart` to load dotenv before `runApp`
    - Import `flutter_dotenv`
    - Change `main()` to `async` and call `await dotenv.load()` before `runApp()`
    - _Requirements: 1.1_

- [x] 2. Implement KeywordModel data model
  - [x] 2.1 Create `lib/models/keyword_model.dart` with the `KeywordModel` class
    - Define `final` fields: `arabic` (String), `translation` (String), `hint` (String), `type` (String)
    - Implement `const` constructor with required named parameters
    - Implement `factory KeywordModel.fromJson(Map<String, dynamic> json)` that extracts all four fields
    - Throw `FormatException` with descriptive message naming the missing field when any required field is missing or null
    - Implement `Map<String, dynamic> toJson()` for round-trip testing
    - _Requirements: 3.5, 3.7_

  - [ ]* 2.2 Write property test for KeywordModel JSON round trip
    - Create `test/models/keyword_model_property_test.dart`
    - **Property 2 (partial): KeywordModel JSON parsing round trip**
    - Generate random valid KeywordModel instances, convert to JSON via `toJson()`, parse back via `fromJson`, assert field equality
    - **Validates: Requirements 3.5, 3.6**

  - [ ]* 2.3 Write property test for KeywordModel missing/null field errors
    - Add to `test/models/keyword_model_property_test.dart`
    - **Property 3 (partial): Missing or null fields produce descriptive errors**
    - Generate valid JSON maps then randomly remove or null-ify one required field, assert `fromJson` throws with field name in message
    - **Validates: Requirements 3.7**

- [x] 3. Implement SessionResponse data model
  - [x] 3.1 Create `lib/models/session_response.dart` with the `SessionResponse` class
    - Define `final` fields: `sessionId` (String), `overview` (List\<String\>), `keywords` (List\<KeywordModel\>)
    - Implement `const` constructor with required named parameters
    - Implement `factory SessionResponse.fromJson(Map<String, dynamic> json)` that parses all fields including nested `keywords` list
    - Throw `FormatException` with descriptive message naming the missing field when any required field is missing or null
    - Implement `Map<String, dynamic> toJson()` for round-trip testing
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.7_

  - [ ]* 3.2 Write property test for SessionResponse JSON round trip
    - Create `test/models/session_response_property_test.dart`
    - **Property 2: SessionResponse JSON parsing round trip**
    - Generate random valid SessionResponse instances (with random KeywordModel lists), convert to JSON, parse back, assert full equality
    - **Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5, 3.6**

  - [ ]* 3.3 Write property test for SessionResponse missing/null field errors
    - Add to `test/models/session_response_property_test.dart`
    - **Property 3: Missing or null required fields produce descriptive errors**
    - Generate valid JSON maps then randomly remove or null-ify one required top-level field, assert `fromJson` throws with field name in message
    - **Validates: Requirements 3.7**

  - [ ]* 3.4 Write unit tests for data models
    - Create `test/models/session_response_test.dart`
    - Test `SessionResponse.fromJson` with a realistic API response snippet
    - Test `KeywordModel.fromJson` with a realistic keyword JSON
    - Test edge cases: empty overview list, empty keywords list
    - _Requirements: 3.1, 3.5_

- [x] 4. Implement SessionService
  - [x] 4.1 Create `lib/services/session_service.dart` with the `SessionService` class
    - Implement `Future<SessionResponse> prepare({List<int>? pages, String? surah, required String familiarity, http.Client? client})`
    - Validate that exactly one of `pages` or `surah` is provided; throw `ArgumentError` with descriptive message otherwise
    - Read `BASE_URL` from `dotenv.env`; throw descriptive error if missing or empty
    - Construct JSON request body with `familiarity` and either `pages` or `surah`
    - Send HTTP POST to `{BASE_URL}/sessions/prepare` with `Content-Type: application/json` and `Authorization: Bearer demo-user-1` headers
    - On 200 response: parse body via `SessionResponse.fromJson` and return
    - On non-200 response: throw `Exception` with status code in message
    - On JSON parse failure: throw `FormatException` indicating parsing failure
    - Propagate network errors without catching
    - _Requirements: 1.1, 1.4, 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 3.1, 4.1, 4.2, 4.3, 5.1, 5.2_

  - [ ]* 4.2 Write property test for request body construction
    - Create `test/services/session_service_property_test.dart`
    - **Property 1: Request body construction correctness**
    - Generate random familiarity strings and either random page lists or surah strings, mock a 200 response, capture the request body, assert it contains exactly the expected fields
    - **Validates: Requirements 2.3, 2.4, 2.5**

  - [ ]* 4.3 Write property test for non-200 status code handling
    - Add to `test/services/session_service_property_test.dart`
    - **Property 4: Non-200 status codes produce exceptions with status code**
    - Generate random non-200 status codes (100–599 excluding 200), mock HTTP response, assert exception message contains the code
    - **Validates: Requirements 4.1**

  - [ ]* 4.4 Write property test for invalid JSON response handling
    - Add to `test/services/session_service_property_test.dart`
    - **Property 5: Invalid JSON responses produce parsing errors**
    - Generate random non-JSON strings, mock HTTP 200 response with that body, assert it throws a parsing error
    - **Validates: Requirements 4.3**

  - [ ]* 4.5 Write property test for input validation
    - Add to `test/services/session_service_property_test.dart`
    - **Property 6: Input validation — exactly one of pages or surah required**
    - Generate random pages and surah values, call with both provided and with neither provided, assert validation error is thrown
    - **Validates: Requirements 5.1, 5.2**

  - [ ]* 4.6 Write unit tests for SessionService
    - Create `test/services/session_service_test.dart`
    - Test POST sent to correct URL `{BASE_URL}/sessions/prepare` (mock client)
    - Test `Authorization: Bearer demo-user-1` header is set
    - Test `Content-Type: application/json` header is set
    - Test throws when `BASE_URL` is missing or empty
    - Test network error propagation
    - Test neither pages nor surah provided throws (edge case)
    - Test both pages and surah provided throws (edge case)
    - _Requirements: 1.4, 2.1, 2.2, 2.6, 4.2, 5.1, 5.2_

- [x] 5. Final checkpoint
  - Run all tests and verify everything passes
  - Verify `.env.example` exists with placeholder `BASE_URL`
  - Verify `.env` is in `.gitignore`
  - Verify `flutter_dotenv` and `http` are in `pubspec.yaml`

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Property tests use the `glados` package for Dart property-based testing
- `SessionService` accepts an optional `http.Client` for mocking in tests
- The `http` package is already in `pubspec.yaml`; only `flutter_dotenv` needs to be added
