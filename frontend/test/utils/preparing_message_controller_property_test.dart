import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect, test;
import 'package:quran_prep/utils/preparing_message_controller.dart';

void main() {
  // Feature: prepare-loading-messages, Property 1: Start and reset always return to the first message
  // **Validates: Requirements 1.3, 2.3, 3.1, 3.3**
  Glados2(any.intInRange(0, 11), any.bool).test(
    'start() and reset() always return to the first message',
    (advanceCount, useStart) {
      final controller = PreparingMessageController();

      // Advance a random number of times to reach an arbitrary state
      for (var i = 0; i < advanceCount; i++) {
        controller.advance();
      }

      // Call either start() or reset() based on the random bool
      if (useStart) {
        controller.start();
      } else {
        controller.reset();
      }

      expect(controller.currentIndex, equals(0));
      expect(
        controller.currentMessage,
        equals(PreparingMessageController.messages[0]),
      );

      // Clean up any timer started by start()
      controller.dispose();
    },
  );

  // Feature: prepare-loading-messages, Property 2: Advance increments the message index by one
  // **Validates: Requirements 2.1**
  Glados(any.intInRange(0, 3)).test(
    'advance() increments the message index by one',
    (startIndex) {
      final controller = PreparingMessageController();

      // Advance to the starting index
      for (var i = 0; i < startIndex; i++) {
        controller.advance();
      }

      final previousIndex = controller.currentIndex;
      expect(previousIndex, equals(startIndex));

      controller.advance();

      expect(controller.currentIndex, equals(previousIndex + 1));
      expect(
        controller.currentMessage,
        equals(PreparingMessageController.messages[previousIndex + 1]),
      );

      controller.dispose();
    },
  );

  // Feature: prepare-loading-messages, Property 3: Advance at the last message is idempotent
  // **Validates: Requirements 2.2**
  Glados(any.intInRange(1, 21)).test(
    'advance() at the last message is idempotent',
    (extraAdvances) {
      final controller = PreparingMessageController();
      final lastIndex = PreparingMessageController.messages.length - 1;

      // Advance to the last message
      for (var i = 0; i < lastIndex; i++) {
        controller.advance();
      }
      expect(controller.currentIndex, equals(lastIndex));

      // Call advance() a random number of additional times (1 to 20)
      for (var i = 0; i < extraAdvances; i++) {
        controller.advance();
      }

      expect(controller.currentIndex, equals(lastIndex));
      expect(
        controller.currentMessage,
        equals(PreparingMessageController.messages[lastIndex]),
      );

      controller.dispose();
    },
  );

  // Feature: prepare-loading-messages, Property 4: All messages end with the ellipsis character
  // **Validates: Requirements 4.2**
  test('all messages end with the ellipsis character (U+2026)', () {
    for (final message in PreparingMessageController.messages) {
      expect(
        message.endsWith('\u2026'),
        isTrue,
        reason: 'Message "$message" should end with the ellipsis character (…)',
      );
    }
  });
}
