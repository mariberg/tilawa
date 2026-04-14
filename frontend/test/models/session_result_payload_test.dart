import 'package:flutter_test/flutter_test.dart';
import 'package:quran_prep/models/keyword_selection_record.dart';
import 'package:quran_prep/models/session_result_payload.dart';

void main() {
  group('SessionResultPayload', () {
    test('toJson includes pages when set', () {
      const payload = SessionResultPayload(
        pages: '50-54',
        keywords: [
          KeywordSelectionRecord(arabic: 'صَبْر', category: 'known'),
        ],
      );
      final json = payload.toJson();
      expect(json['pages'], '50-54');
      expect(json.containsKey('surah'), isFalse);
      expect(json['keywords'], hasLength(1));
    });

    test('toJson includes surah when set', () {
      const payload = SessionResultPayload(
        surah: 'Al-Baqarah',
        keywords: [
          KeywordSelectionRecord(arabic: 'هُدًى', category: 'not_sure'),
        ],
      );
      final json = payload.toJson();
      expect(json['surah'], 'Al-Baqarah');
      expect(json.containsKey('pages'), isFalse);
    });

    test('toJson omits both pages and surah when both null', () {
      const payload = SessionResultPayload(
        keywords: [
          KeywordSelectionRecord(arabic: 'تَقْوَى', category: 'review'),
        ],
      );
      final json = payload.toJson();
      expect(json.containsKey('pages'), isFalse);
      expect(json.containsKey('surah'), isFalse);
    });

    test('fromJson with pages creates correct instance', () {
      final payload = SessionResultPayload.fromJson({
        'pages': '1-5',
        'keywords': [
          {'arabic': 'صَبْر', 'category': 'known'},
        ],
      });
      expect(payload.pages, '1-5');
      expect(payload.surah, isNull);
      expect(payload.keywords, hasLength(1));
      expect(payload.keywords[0].arabic, 'صَبْر');
      expect(payload.keywords[0].category, 'known');
    });

    test('fromJson with surah creates correct instance', () {
      final payload = SessionResultPayload.fromJson({
        'surah': 'Al-Fatiha',
        'keywords': [
          {'arabic': 'هُدًى', 'category': 'review'},
        ],
      });
      expect(payload.surah, 'Al-Fatiha');
      expect(payload.pages, isNull);
    });

    test('round trip preserves values with pages', () {
      const original = SessionResultPayload(
        pages: '10-15',
        keywords: [
          KeywordSelectionRecord(arabic: 'صَبْر', category: 'known'),
          KeywordSelectionRecord(arabic: 'هُدًى', category: 'not_sure'),
        ],
      );
      final restored = SessionResultPayload.fromJson(original.toJson());
      expect(restored.pages, original.pages);
      expect(restored.surah, original.surah);
      expect(restored.keywords.length, original.keywords.length);
      for (var i = 0; i < original.keywords.length; i++) {
        expect(restored.keywords[i].arabic, original.keywords[i].arabic);
        expect(restored.keywords[i].category, original.keywords[i].category);
      }
    });
  });
}
