import 'package:flutter_test/flutter_test.dart';
import 'package:quran_prep/utils/preparing_message_controller.dart';

void main() {
  group('PreparingMessageController', () {
    // Req 4.1: messages contains exactly 4 messages in the specified order
    test('messages contains exactly 4 specified messages in order', () {
      expect(PreparingMessageController.messages, [
        'Analysing the passage…',
        'Identifying key vocabulary for your level…',
        'Ranking keywords by importance…',
        'Almost ready…',
      ]);
    });

    // Req 2.1: interval equals 2500ms
    test('interval equals Duration(milliseconds: 2500)', () {
      expect(
        PreparingMessageController.interval,
        const Duration(milliseconds: 2500),
      );
    });

    // Req 1.3: newly constructed controller starts at index 0
    test('newly constructed controller has currentIndex == 0', () {
      final controller = PreparingMessageController();
      expect(controller.currentIndex, 0);
      expect(controller.currentMessage, 'Analysing the passage…');
      controller.dispose();
    });

    // Req 2.1: onChanged callback is invoked on each advance() call
    test('onChanged is invoked on each advance() when not at last message', () {
      var callCount = 0;
      final controller = PreparingMessageController(
        onChanged: () => callCount++,
      );

      controller.advance();
      expect(callCount, 1);

      controller.advance();
      expect(callCount, 2);

      controller.advance();
      expect(callCount, 3);

      controller.dispose();
    });

    // Req 2.2: onChanged is NOT invoked when advance() is called at the last message
    test('onChanged is not invoked when advance() is called at last message', () {
      var callCount = 0;
      final controller = PreparingMessageController(
        onChanged: () => callCount++,
      );

      // Advance to the last message (index 3)
      for (var i = 0; i < PreparingMessageController.messages.length - 1; i++) {
        controller.advance();
      }
      expect(controller.isComplete, isTrue);

      final countBeforeExtra = callCount;

      // Calling advance() at the last message should not invoke onChanged
      controller.advance();
      expect(callCount, countBeforeExtra);

      controller.advance();
      expect(callCount, countBeforeExtra);

      controller.dispose();
    });
  });
}
