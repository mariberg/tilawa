import 'package:flutter_test/flutter_test.dart';
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
        'status': 'not_sure',
      });
      expect(record.arabic, 'هُدًى');
      expect(record.translation, 'guidance');
      expect(record.status, 'not_sure');
    });

    test('round trip preserves values', () {
      const original = KeywordSelectionRecord(
        arabic: 'تَقْوَى',
        translation: 'piety',
        status: 'review',
      );
      final restored = KeywordSelectionRecord.fromJson(original.toJson());
      expect(restored.arabic, original.arabic);
      expect(restored.translation, original.translation);
      expect(restored.status, original.status);
    });
  });
}
