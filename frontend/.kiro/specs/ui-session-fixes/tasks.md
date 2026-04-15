# UI Session Fixes — Tasks

## Tasks

- [x] 1. Limit recent sessions list to 5 on Entry Screen
  - [x] 1.1 In `lib/screens/entry_screen.dart`, add `.take(5)` to `_recentSessions!` before `.asMap().entries.expand(...)` in the `build()` method so only the first 5 sessions are rendered
- [x] 2. Replace subtle button spinner with prominent full-screen loading indicator
  - [x] 2.1 In `lib/screens/entry_screen.dart`, wrap the `Scaffold` body content in a `Stack` widget
  - [x] 2.2 Add an overlay child to the `Stack` that shows a centered `CircularProgressIndicator` when `_isPreparing` is true (use a semi-transparent background container covering the full screen)
  - [x] 2.3 Update the `ElevatedButton` child to always show `Text('Prepare')` and keep `onPressed: null` when `_isPreparing` is true (remove the small 20×20 spinner from inside the button)
- [x] 3. Pass surah name through navigation arguments
  - [x] 3.1 In `lib/screens/entry_screen.dart` `_prepare()` method, add `'surahName': _selectedSurah?.nameSimple` to the arguments map passed to `Navigator.pushNamed(context, '/prep', ...)`
- [x] 4. Dynamic header in Prep Screen
  - [x] 4.1 In `lib/screens/prep_screen.dart`, add a `String? _surahName` field and extract it from `args['surahName']` in `didChangeDependencies`
  - [x] 4.2 Replace the hardcoded `'Surah Al-Baqarah · Pages 50–54'` header text with a computed string using `_surahName` and `_pages` (format: "Surah X · Pages Y", "Surah X", "Pages Y", or "Session" as fallback)
  - [x] 4.3 In `_completeSession()`, forward `'surahName': _surahName` in the arguments map passed to `Navigator.pushReplacementNamed(context, '/recitation', ...)`
- [x] 5. Dynamic header in Recitation Screen
  - [x] 5.1 In `lib/screens/recitation_screen.dart`, add a `String? _surahName` field and extract it from `args['surahName']` in `didChangeDependencies`
  - [x] 5.2 Replace the hardcoded `'Surah Al-Baqarah · Pages 50–54'` header text with the same computed string logic as the Prep Screen
