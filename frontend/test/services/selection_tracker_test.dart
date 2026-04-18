import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect, test, group;
import 'package:quran_prep/services/selection_tracker.dart';

void main() {
  group('SelectionTracker', () {
    // --- Unit tests (2.4, 2.5) ---

    test('record() with "not_sure" throws ArgumentError', () {
      final tracker = SelectionTracker();
      expect(
        () => tracker.record('صَبْر', 'patience', 'not_sure'),
        throwsArgumentError,
      );
    });

    test('record() with "review" throws ArgumentError', () {
      final tracker = SelectionTracker();
      expect(
        () => tracker.record('صَبْر', 'patience', 'review'),
        throwsArgumentError,
      );
    });
  });

  // Feature: keyword-rating-simplification, Property 1: SelectionTracker recording fidelity
  // **Validates: Requirements 2.1, 3.1, 4.3**
  Glados2(any.nonEmptyLetterOrDigits, any.nonEmptyLetterOrDigits).test(
    'recording a keyword with a valid status preserves that status in getRecords()',
    (arabic, translation) {
      for (final status in ['known', 'not_known']) {
        final tracker = SelectionTracker();
        tracker.record(arabic, translation, status);
        final records = tracker.getRecords();
        expect(records.length, equals(1));
        expect(records.first.arabic, equals(arabic));
        expect(records.first.translation, equals(translation));
        expect(records.first.status, equals(status));
      }
    },
  );

  // Feature: keyword-rating-simplification, Property 2: SelectionTracker rejects invalid statuses
  // **Validates: Requirements 4.1, 4.2**
  Glados(any.nonEmptyLetterOrDigits).test(
    'record() throws ArgumentError for any status that is not "known" or "not_known"',
    (status) {
      if (status == 'known' || status == 'not_known') return;
      final tracker = SelectionTracker();
      expect(
        () => tracker.record('test', 'test', status),
        throwsArgumentError,
      );
    },
  );
}
