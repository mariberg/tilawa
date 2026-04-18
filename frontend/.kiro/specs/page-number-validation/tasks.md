# Tasks — Page Number Validation Bugfix

## Task 1: Add bounds validation to `parsePageRange()` in `page_utils.dart`

- [x] 1.1 Add `const maxQuranPage = 604` constant at the top of `lib/utils/page_utils.dart`
- [ ] 1.2 Add bounds validation after range parsing: check `start >= 1`, `end <= 604`, `start <= end`; throw `FormatException` with descriptive message if violated
- [ ] 1.3 Add bounds validation after single page parsing: check `page >= 1` and `page <= 604`; throw `FormatException` with descriptive message if violated

## Task 2: Refactor `_parsePages()` in `entry_screen.dart` to delegate to `parsePageRange()`

- [x] 2.1 Refactor `_parsePages()` to use `parsePageRange()` for validation instead of duplicating regex logic, letting `FormatException` propagate to the existing catch block in `_prepare()`

## Task 3: Write unit tests for bounds validation

- [ ] 3.1 Create `test/utils/page_utils_test.dart` with unit tests for out-of-bounds rejection (page 0, 605, 700, range 600-610, reversed range 100-50)
- [ ] 3.2 Add unit tests for valid boundary values (page 1, page 604, range 1-604, range 50-54)
- [ ] 3.3 Add unit tests for non-page inputs returning null (empty string, surah names, "Pages " prefix format)

## Task 4: Write property-based tests for page validation

- [ ] 4.1 [PBT: Property 1] Write property test: for any page number outside [1, 604] or any range with start > end, `parsePageRange()` throws `FormatException`
- [ ] 4.2 [PBT: Property 2] Write property test: for any valid page in [1, 604] and any valid range with 1 ≤ start ≤ end ≤ 604, `parsePageRange()` returns correct `(start, end, span)` tuple unchanged

## Task 5: Verify `nextPageRange()` output stays valid

- [ ] 5.1 Add test that `nextPageRange()` output for boundary pages (e.g. page 604) is handled gracefully — `parsePageRange(nextPageRange(600, 604, 5))` should throw since 605-609 exceeds 604
