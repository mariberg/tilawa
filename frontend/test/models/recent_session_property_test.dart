import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect, test;
import 'package:quran_prep/models/recent_session.dart';

void main() {
  // Feature: null-feeling-session-display
  // 3.1 (PBT Exploration) Property 1: Verify fromJson does NOT throw for null
  // feeling on FIXED code (exploration — confirms bug condition is handled)
  // **Validates: Requirements 2.1**
  Glados2(any.letterOrDigits, any.intInRange(1, 115)).test(
    'Exploration: fromJson does not throw for null feeling on fixed code',
    (sessionId, surah) {
      final json = {
        'sessionId': sessionId,
        'surah': surah,
        'feeling': null,
        'createdAt': '2025-01-01T00:00:00.000Z',
      };

      // On unfixed code this would throw FormatException.
      // On fixed code it should parse successfully.
      final session = RecentSession.fromJson(json);
      expect(session.feeling, isNull);
      expect(session.sessionId, sessionId);
      expect(session.surah, surah);
    },
  );

  // 3.2 (PBT Fix) Property 1: Verify fromJson parses null/"null" feeling
  // successfully with feeling == null on FIXED code
  // **Validates: Requirements 2.1, 2.2**
  Glados2(any.letterOrDigits, any.choose([null, 'null'])).test(
    'Fix: fromJson parses null and "null" feeling as null',
    (sessionId, rawFeeling) {
      final json = {
        'sessionId': sessionId,
        'pages': '1-5',
        'feeling': rawFeeling,
        'createdAt': '2025-06-15T12:00:00.000Z',
      };

      final session = RecentSession.fromJson(json);
      expect(session.feeling, isNull);
      expect(session.sessionId, sessionId);
      expect(session.pages, '1-5');
    },
  );

  // 3.3 (PBT Preservation) Property 2: Verify fromJson produces identical
  // results for random valid non-null, non-"null" feeling strings
  // **Validates: Requirements 3.1, 3.2, 3.3**
  Glados2(
    any.letterOrDigits,
    any.choose(['revisit', 'good', 'struggling', 'confident', 'okay']),
  ).test(
    'Preservation: fromJson preserves valid non-null feeling strings',
    (sessionId, feeling) {
      final json = {
        'sessionId': sessionId,
        'pages': '10-14',
        'feeling': feeling,
        'createdAt': '2025-03-20T08:30:00.000Z',
      };

      final session = RecentSession.fromJson(json);
      expect(session.feeling, equals(feeling));
      expect(session.sessionId, sessionId);
    },
  );

  // 3.4 (PBT Preservation) Property 2: Verify round-trip consistency for
  // random valid sessions with non-null feeling
  // **Validates: Requirements 3.1, 3.2, 3.3, 3.4**
  Glados2(
    any.letterOrDigits,
    any.choose(['revisit', 'good', 'struggling', 'confident', 'okay']),
  ).test(
    'Preservation: toJson -> fromJson round-trip preserves all fields',
    (sessionId, feeling) {
      final original = RecentSession(
        sessionId: sessionId,
        surah: 2,
        feeling: feeling,
        createdAt: DateTime.utc(2025, 1, 15),
      );

      final restored = RecentSession.fromJson(original.toJson());

      expect(restored.sessionId, equals(original.sessionId));
      expect(restored.surah, equals(original.surah));
      expect(restored.pages, equals(original.pages));
      expect(restored.feeling, equals(original.feeling));
      expect(restored.createdAt, equals(original.createdAt));
    },
  );
}
