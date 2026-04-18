# Tasks

- [x] 1. Add reset mechanism to FamiliarityPills widget
  - [x] 1.1 Rename `_FamiliarityPillsState` to `FamiliarityPillsState` (make public) in `lib/widgets/familiarity_pills.dart`
  - [x] 1.2 Add a `reset()` method to `FamiliarityPillsState` that calls `setState(() => _selected = -1)`
- [x] 2. Wire up reset in EntryScreen
  - [x] 2.1 Add a `final _familiarityKey = GlobalKey<FamiliarityPillsState>()` field to `_EntryScreenState` in `lib/screens/entry_screen.dart`
  - [x] 2.2 Pass `key: _familiarityKey` to the `FamiliarityPills` widget in the build method
  - [x] 2.3 In `didPopNext()`, add `_familiarityKey.currentState?.reset()` and reset `_familiarity = 'New'` inside the `setState` block
- [x] 3. Write tests
  - [x] 3.1 Write a unit test verifying `FamiliarityPillsState.reset()` clears the selection
  - [x] 3.2 Write a widget test verifying familiarity pills are visually cleared after `didPopNext()` is triggered
  - [x] 3.3 Write a widget test verifying `_familiarity` resets to `'New'` after `didPopNext()`
