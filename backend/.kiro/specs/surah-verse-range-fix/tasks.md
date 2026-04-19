# Tasks — Surah Verse Range Fix

## Task 1: Fix `resolveChapterAndVerse` surah branch

- [x] 1.1 In `src/sessions.mjs`, update the `if (surah != null)` branch of `resolveChapterAndVerse` to call `await fetchVersesForChapter(Number(surah))` instead of returning hardcoded values
- [x] 1.2 Add an empty-response guard: if the returned verses array is empty, throw `new Error(\`No verses returned for chapter ${surah}\`)`
- [x] 1.3 Extract the last verse from the returned array, parse its `verseKey` to get the last verse number, and set `verseNumber` and `endVerseKey` accordingly (keep `startVerseKey` as `{surah}:1`)

## Task 2: Write exploratory bug condition tests (PBT)

- [x] 2.1 Create `tests/property/sessions.property.test.mjs` with a property test that generates random surah numbers (1–114), mocks `fetchVersesForChapter` to return a verse array of known length, calls `resolveChapterAndVerse(surah, undefined)`, and asserts `endVerseKey` equals `{surah}:{lastVerse}` and `verseNumber` equals the last verse number ~PBT(Property 1: Bug Condition — Surah-based sessions resolve correct last verse)

## Task 3: Write preservation tests (PBT)

- [x] 3.1 In `tests/property/sessions.property.test.mjs`, add a property test that generates random page range strings, mocks `fetchVersesForPage` to return consistent verse arrays, calls `resolveChapterAndVerse(null, pages)`, and asserts the result matches the expected page-based resolution output ~PBT(Property 2: Preservation — Page-based sessions produce identical results)

## Task 4: Write unit tests

- [x] 4.1 Create `tests/unit/sessions.test.mjs` with unit tests for the fixed surah branch: test with surah 108 (3 verses), surah 2 (286 verses), surah 69 (52 verses)
- [x] 4.2 Add a unit test for the error case: surah where `fetchVersesForChapter` returns an empty array should throw an error
- [x] 4.3 Add a unit test verifying the page-based path still works correctly (preservation)
