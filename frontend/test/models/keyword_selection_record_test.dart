import 'package:flutter_test/flutter_test.dart';
import 'package:quran_prep/models/keyword_selection_record.dart';

void main() {
  group('KeywordSelectionRecord', () {
    test('toJson returns correct map', () {
      const record = KeywordSelectionRecord(arabic: 'صَبْر', category: 'known');
      expect(record.toJson(), {'arabic': 'صَبْر', 'category': 'known'});
    });

    test('fromJson creates correct instance', () {
      final record = KeywordSelectionRecord.fromJson({
        'arabic': 'هُدًى',
        'category': 'not_sure',
      });
      expect(record.arabic, 'هُدًى');
      expect(record.category, 'not_sure');
    });

    test('round trip preserves values', () {
      const original = KeywordSelectionRecord(arabic: 'تَقْوَى', category: 'review');
      final restored = KeywordSelectionRecord.fromJson(original.toJson());
      expect(restored.arabic, original.arabic);
      expect(restored.category, original.category);
    });
  });
}
