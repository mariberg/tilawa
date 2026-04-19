# Bugfix Requirements Document

## Introduction

When a session is created using a surah number (rather than page numbers), the `resolveChapterAndVerse` function in `src/sessions.mjs` hardcodes `verseNumber: 1` and sets both `startVerseKey` and `endVerseKey` to `{surah}:1`. This causes the Reading Sessions API sync to always report verse 1 regardless of what was actually read, and the Activity Days API sync to send a collapsed range (e.g. `69:1-69:1`) instead of the full surah range (e.g. `69:1-69:52`), resulting in near-zero `pagesRead` and `versesRead` counts.

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN a session is created with a surah number THEN the system hardcodes `verseNumber` to `1` in the resolved chapter/verse data, ignoring the actual last verse of the surah.

1.2 WHEN a session is created with a surah number THEN the system sets `endVerseKey` to `{surah}:1` (identical to `startVerseKey`), producing a collapsed verse range.

1.3 WHEN the collapsed verse range from a surah-based session is synced to the Activity Days API THEN the system reports a range like `69:1-69:1`, resulting in near-zero `pagesRead` and `versesRead` counts.

1.4 WHEN the hardcoded verse number from a surah-based session is synced to the Reading Sessions API THEN the system always reports `verseNumber: 1` regardless of the surah's actual verse count.

### Expected Behavior (Correct)

2.1 WHEN a session is created with a surah number THEN the system SHALL fetch the verses for that chapter (using the existing `fetchVersesForChapter` function) and resolve `verseNumber` to the last verse number of the surah.

2.2 WHEN a session is created with a surah number THEN the system SHALL set `endVerseKey` to the verse key of the last verse in the surah (e.g. `69:52`), while `startVerseKey` remains `{surah}:1`.

2.3 WHEN the full verse range from a surah-based session is synced to the Activity Days API THEN the system SHALL send the complete range (e.g. `69:1-69:52`), resulting in accurate `pagesRead` and `versesRead` counts.

2.4 WHEN the resolved verse number from a surah-based session is synced to the Reading Sessions API THEN the system SHALL report the last verse number of the surah (e.g. `verseNumber: 52` for surah 69).

### Unchanged Behavior (Regression Prevention)

3.1 WHEN a session is created with page numbers THEN the system SHALL CONTINUE TO fetch verses for the first and last pages and resolve `startVerseKey`, `endVerseKey`, `chapterNumber`, and `verseNumber` from the actual page verse data.

3.2 WHEN a session is created with page numbers THEN the system SHALL CONTINUE TO sync the correct verse range to the Activity Days API.

3.3 WHEN a session is created with page numbers THEN the system SHALL CONTINUE TO sync the correct chapter and verse number to the Reading Sessions API.

3.4 WHEN `resolveChapterAndVerse` is called with a surah number and the Quran API returns no verses THEN the system SHALL CONTINUE TO throw an error (consistent with the page-based path's error handling for empty responses).
