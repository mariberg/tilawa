import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect, test, group;
import 'package:quran_prep/models/keyword_selection_record.dart';

void main() {
  group('KeywordSelectionRecord', () {
    test('toJson returns correct map', () {
      const record = KeywordSelectionRecord(
        arabic: 'صَبْر',
        translation: 'patience',
        status: 'known',
      );
      expect(record.toJson(), {
        'arabic': 'صَبْر',
        'translation': 'patience',
        'status': 'known',
      });
    });

    test('fromJson creates correct instance', () {
      final record = KeywordSelectionRecord.fromJson({
        'arabic': 'هُدًى',
        'translation': 'guidance',
        'status': 'not_known',
      });
      expect(record.arabic, 'هُدًى');
      expect(record.translation, 'guidance');
      expect(record.status, 'not_known');
    });

    test('round trip preserves values', () {
      const original = KeywordSelectionRecord(
        arabic: 'تَقْوَى',
        translation: 'piety',
        status: 'not_known',
      );
      final restored = KeywordSelectionRecord.fromJson(original.toJson());
      expect(restored.arabic, original.arabic);
      expect(restored.translation, original.translation);
      expect(restored.status, original.status);
    });

    test('fromJson with "not_sure" throws FormatException', () {
      expect(
        () => KeywordSelectionRecord.fromJson({
          'arabic': 'صَبْر',
          'translation': 'patience',
          'status': 'not_sure',
        }),
        throwsFormatException,
      );
    });

    test('fromJson with "review" throws FormatException', () {
      expect(
        () => KeywordSelectionRecord.fromJson({
          'arabic': 'صَبْر',
          'translation': 'patience',
          'status': 'review',
        }),
        throwsFormatException,
      );
    });
  });

  // Feature: keyword-rating-simplification, Property 4: KeywordSelectionRecord serialization round trip
  // **Validates: Requirements 5.2, 5.3**
  Glados2(any.nonEmptyLetterOrDigits, any.nonEmptyLetterOrDigits).test(
    'toJson then fromJson produces identical fields for any valid record',
    (arabic, translation) {
      for (final status in KeywordSelectionRecord.validStatuses) {
        final original = KeywordSelectionRecord(
          arabic: arabic,
          translation: translation,
          status: status,
        );
        final restored = KeywordSelectionRecord.fromJson(original.toJson());
        expect(restored.arabic, equals(original.arabic));
        expect(restored.translation, equals(original.translation));
        expect(restored.status, equals(original.status));
      }
    },
  );
}
