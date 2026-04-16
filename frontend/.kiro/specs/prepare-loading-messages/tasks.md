# Tasks: Prepare Loading Messages

## Task 1: Create PreparingMessageController

- [x] 1.1 Create `lib/utils/preparing_message_controller.dart` with static `messages` list, static `interval` duration, `currentIndex`, `currentMessage`, `isComplete`, `start()`, `advance()`, `reset()`, and `dispose()` methods
- [x] 1.2 Write property test: Start and reset always return to the first message (Property 1)
- [x] 1.3 Write property test: Advance increments the message index by one (Property 2)
- [x] 1.4 Write property test: Advance at the last message is idempotent (Property 3)
- [x] 1.5 Write property test: All messages end with the ellipsis character (Property 4)
- [x] 1.6 Write unit tests: messages list contains exactly 4 specified messages, interval is 2500ms, onChanged callback behavior

## Task 2: Integrate PreparingMessageController into EntryScreen

- [x] 2.1 Add `PreparingMessageController` field to `_EntryScreenState` and initialize with `onChanged` callback that calls `setState`
- [x] 2.2 Call `_messageController.start()` in `_prepare()` when setting `_isPreparing = true`
- [x] 2.3 Call `_messageController.reset()` in the `finally` block of `_prepare()` before setting `_isPreparing = false`
- [x] 2.4 Call `_messageController.dispose()` in `_EntryScreenState.dispose()`

## Task 3: Update the loading overlay UI

- [x] 3.1 Replace the plain `CircularProgressIndicator` in the overlay with a `Column` containing the spinner and a `Text` widget showing `_messageController.currentMessage`
- [x] 3.2 Style the progress message text using `AppTextStyles` and `AppColors` theme tokens (e.g. white or light color for readability on the semi-transparent overlay)
