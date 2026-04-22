import 'package:flutter_test/flutter_test.dart';
import 'package:quran_prep/models/recent_session.dart';

void main() {
  group('RecentSession null feeling handling', () {
    test('fromJson() with feeling: null parses successfully with feeling == null', () {
      final session = RecentSession.fromJson({
        'sessionId': 'test-123',
        'pages': '1-5',
        'createdAt': '2025-01-01T00:00:00.000Z',
        'feeling': null,
      });

      expect(session.feeling, isNull);
      expect(session.sessionId, 'test-123');
      expect(session.pages, '1-5');
      expect(session.createdAt, DateTime.utc(2025, 1, 1));
    });

    test('fromJson() with feeling: "null" parses successfully with feeling == null', () {
      final session = RecentSession.fromJson({
        'sessionId': 'test-123',
        'pages': '1-5',
        'createdAt': '2025-01-01T00:00:00.000Z',
        'feeling': 'null',
      });

      expect(session.feeling, isNull);
      expect(session.sessionId, 'test-123');
    });

    test('fromJson() with missing feeling key parses successfully with feeling == null', () {
      final session = RecentSession.fromJson({
        'sessionId': 'test-123',
        'pages': '1-5',
        'createdAt': '2025-01-01T00:00:00.000Z',
      });

      expect(session.feeling, isNull);
      expect(session.sessionId, 'test-123');
      expect(session.pages, '1-5');
    });

    test('fromJson() with valid feeling strings continues to work', () {
      final revisitSession = RecentSession.fromJson({
        'sessionId': 'test-revisit',
        'pages': '1-5',
        'createdAt': '2025-01-01T00:00:00.000Z',
        'feeling': 'revisit',
      });
      expect(revisitSession.feeling, 'revisit');

      final goodSession = RecentSession.fromJson({
        'sessionId': 'test-good',
        'surah': 2,
        'createdAt': '2025-01-01T00:00:00.000Z',
        'feeling': 'good',
      });
      expect(goodSession.feeling, 'good');
      expect(goodSession.surah, 2);
    });

    test('toJson() omits feeling when null and includes it when non-null', () {
      final nullFeelingSession = RecentSession(
        sessionId: 'test-123',
        pages: '1-5',
        createdAt: DateTime.utc(2025, 1, 1),
      );
      final nullJson = nullFeelingSession.toJson();
      expect(nullJson.containsKey('feeling'), isFalse);
      expect(nullJson['sessionId'], 'test-123');

      final withFeelingSession = RecentSession(
        sessionId: 'test-456',
        pages: '10-14',
        feeling: 'revisit',
        createdAt: DateTime.utc(2025, 1, 1),
      );
      final withJson = withFeelingSession.toJson();
      expect(withJson.containsKey('feeling'), isTrue);
      expect(withJson['feeling'], 'revisit');
    });

    test('round-trip toJson() → fromJson() for sessions with null and non-null feeling', () {
      // Round-trip with null feeling
      final nullFeeling = RecentSession(
        sessionId: 'test-null',
        pages: '1-5',
        createdAt: DateTime.utc(2025, 1, 1),
      );
      final restoredNull = RecentSession.fromJson(nullFeeling.toJson());
      expect(restoredNull.sessionId, nullFeeling.sessionId);
      expect(restoredNull.pages, nullFeeling.pages);
      expect(restoredNull.feeling, isNull);
      expect(restoredNull.createdAt, nullFeeling.createdAt);

      // Round-trip with non-null feeling
      final withFeeling = RecentSession(
        sessionId: 'test-revisit',
        surah: 3,
        feeling: 'revisit',
        createdAt: DateTime.utc(2025, 6, 15),
      );
      final restoredWith = RecentSession.fromJson(withFeeling.toJson());
      expect(restoredWith.sessionId, withFeeling.sessionId);
      expect(restoredWith.surah, withFeeling.surah);
      expect(restoredWith.feeling, 'revisit');
      expect(restoredWith.createdAt, withFeeling.createdAt);
    });
  });
}
