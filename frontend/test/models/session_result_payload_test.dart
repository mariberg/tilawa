import 'package:flutter_test/flutter_test.dart';
import 'package:quran_prep/models/keyword_selection_record.dart';
import 'package:quran_prep/models/session_result_payload.dart';

void main() {
  group('SessionResultPayload', () {
    test('toJson includes pages when set', () {
      const payload = SessionResultPayload(
        pages: '50-54',
        durationSecs: 120,
        keywords: [
          KeywordSelectionRecord(
            arabic: 'صَبْر',
            translation: 'patience',
            status: 'known',
          ),
        ],
      );
      final json = payload.toJson();
      expect(json['pages'], '50-54');
      expect(json.containsKey('surah'), isFalse);
      expect(json['durationSecs'], 120);
      expect(json['keywords'], hasLength(1));
    });

    test('toJson includes surah when set', () {
      const payload = SessionResultPayload(
        surah: 2,
        durationSecs: 90,
        keywords: [
          KeywordSelectionRecord(
            arabic: 'هُدًى',
            translation: 'guidance',
            status: 'not_sure',
          ),
        ],
      );
      final json = payload.toJson();
      expect(json['surah'], 2);
      expect(json.containsKey('pages'), isFalse);
    });

    test('toJson omits both pages and surah when both null', () {
      const payload = SessionResultPayload(
        durationSecs: 60,
        keywords: [
          KeywordSelectionRecord(
            arabic: 'تَقْوَى',
            translation: 'piety',
            status: 'review',
          ),
        ],
      );
      final json = payload.toJson();
      expect(json.containsKey('pages'), isFalse);
      expect(json.containsKey('surah'), isFalse);
      expect(json['durationSecs'], 60);
    });

    test('fromJson with pages creates correct instance', () {
      final payload = SessionResultPayload.fromJson({
        'pages': '1-5',
        'durationSecs': 100,
        'keywords': [
          {'arabic': 'صَبْر', 'translation': 'patience', 'status': 'known'},
        ],
      });
      expect(payload.pages, '1-5');
      expect(payload.surah, isNull);
      expect(payload.durationSecs, 100);
      expect(payload.keywords, hasLength(1));
      expect(payload.keywords[0].arabic, 'صَبْر');
      expect(payload.keywords[0].status, 'known');
    });

    test('fromJson with surah creates correct instance', () {
      final payload = SessionResultPayload.fromJson({
        'surah': 1,
        'durationSecs': 80,
        'keywords': [
          {'arabic': 'هُدًى', 'translation': 'guidance', 'status': 'review'},
        ],
      });
      expect(payload.surah, 1);
      expect(payload.pages, isNull);
    });

    test('round trip preserves values with pages', () {
      const original = SessionResultPayload(
        pages: '10-15',
        durationSecs: 150,
        keywords: [
          KeywordSelectionRecord(
            arabic: 'صَبْر',
            translation: 'patience',
            status: 'known',
          ),
          KeywordSelectionRecord(
            arabic: 'هُدًى',
            translation: 'guidance',
            status: 'not_sure',
          ),
        ],
      );
      final restored = SessionResultPayload.fromJson(original.toJson());
      expect(restored.pages, original.pages);
      expect(restored.surah, original.surah);
      expect(restored.durationSecs, original.durationSecs);
      expect(restored.keywords.length, original.keywords.length);
      for (var i = 0; i < original.keywords.length; i++) {
        expect(restored.keywords[i].arabic, original.keywords[i].arabic);
        expect(restored.keywords[i].translation, original.keywords[i].translation);
        expect(restored.keywords[i].status, original.keywords[i].status);
      }
    });
  });
}
