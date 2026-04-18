# Bugfix Requirements Document

## Introduction

The app accepts page numbers above 604 when creating a new session. The Quran has exactly 604 pages, so any page number exceeding this limit should be rejected. Additionally, page numbers below 1 and ranges where the start page exceeds the end page are not validated. This bug exists in both the `_parsePages()` method in `entry_screen.dart` and the `parsePageRange()` utility in `page_utils.dart`, and no bounds checking occurs before the session is sent to the backend via `SessionService.prepare()`.

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN a user enters a single page number greater than 604 (e.g. "700") THEN the system accepts it and sends it to the backend without error

1.2 WHEN a user enters a page range where the end page exceeds 604 (e.g. "600-610") THEN the system accepts it and sends it to the backend without error

1.3 WHEN a user enters a page number of 0 or a negative number THEN the system accepts it and sends it to the backend without error

1.4 WHEN a user enters a page range where the start page is greater than the end page (e.g. "100-50") THEN the system accepts it and sends it to the backend without error

### Expected Behavior (Correct)

2.1 WHEN a user enters a single page number greater than 604 THEN the system SHALL reject the input and display a validation error indicating the maximum page is 604

2.2 WHEN a user enters a page range where the end page exceeds 604 THEN the system SHALL reject the input and display a validation error indicating the maximum page is 604

2.3 WHEN a user enters a page number less than 1 THEN the system SHALL reject the input and display a validation error indicating the minimum page is 1

2.4 WHEN a user enters a page range where the start page is greater than the end page THEN the system SHALL reject the input and display a validation error indicating the start page must not exceed the end page

### Unchanged Behavior (Regression Prevention)

3.1 WHEN a user enters a valid single page number between 1 and 604 (e.g. "50") THEN the system SHALL CONTINUE TO accept the input and proceed with session preparation

3.2 WHEN a user enters a valid page range within 1–604 where start ≤ end (e.g. "50-54") THEN the system SHALL CONTINUE TO accept the input and proceed with session preparation

3.3 WHEN a user enters a surah name instead of page numbers THEN the system SHALL CONTINUE TO look up the surah and proceed with session preparation

3.4 WHEN a user taps a recent session to auto-fill page numbers THEN the system SHALL CONTINUE TO populate the text field with the correct next page range
