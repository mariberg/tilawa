# Tasks — Lemma-Based Keyword Filter Bugfix

## Task 1: Implement the fix

- [x] 1.1 Update Filter 1 call site in `prepareSession` to use `k.lemma || k.arabic` instead of `k.arabic`
- [x] 1.2 Update `filterKnownKeywords` to use `k.lemma || k.arabic` instead of `k.arabic`

## Task 2: Unit tests

- [x] 2.1 Add unit test: `filterKnownKeywords` excludes keyword when `lemma` matches known set but `arabic` does not
- [x] 2.2 Add unit test: `filterKnownKeywords` falls back to `arabic` when `lemma` is falsy (undefined, null, empty string)
- [x] 2.3 Add unit test: `prepareSession` Filter 1 excludes keyword when `lemma` matches exclusion set

## Task 3: Property-based tests

- [x] 3.1 [PBT: Property 1] For any keyword with a truthy `lemma` matching the exclusion/known set, the keyword is excluded from output
- [x] 3.2 [PBT: Property 2] For any keyword without a `lemma`, the fixed filter produces the same result as filtering on `k.arabic`
