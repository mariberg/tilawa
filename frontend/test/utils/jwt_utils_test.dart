import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_prep/utils/jwt_utils.dart';

/// Helper: builds a minimal JWT string (header.payload.signature)
/// from a given payload map.
String _buildJwt(Map<String, dynamic> payload) {
  final header = base64Url.encode(utf8.encode('{"alg":"RS256","typ":"JWT"}'));
  final body = base64Url.encode(utf8.encode(jsonEncode(payload)));
  const signature = 'fake-signature';
  return '$header.$body.$signature';
}

void main() {
  group('decodeJwtPayload', () {
    test('decodes a valid JWT payload with sub, name, email', () {
      final payload = {'sub': 'user-123', 'name': 'Ali', 'email': 'ali@example.com'};
      final jwt = _buildJwt(payload);

      final result = decodeJwtPayload(jwt);

      expect(result['sub'], 'user-123');
      expect(result['name'], 'Ali');
      expect(result['email'], 'ali@example.com');
    });

    test('throws FormatException for empty string', () {
      expect(() => decodeJwtPayload(''), throwsFormatException);
    });

    test('throws FormatException for single-part string', () {
      expect(() => decodeJwtPayload('abc'), throwsFormatException);
    });

    test('throws FormatException for two-part string', () {
      expect(() => decodeJwtPayload('abc.def'), throwsFormatException);
    });

    test('throws FormatException for four-part string', () {
      expect(() => decodeJwtPayload('a.b.c.d'), throwsFormatException);
    });

    test('decodes payload with additional claims', () {
      final payload = {
        'sub': 'u1',
        'name': 'Test',
        'email': 'test@test.com',
        'iat': 1700000000,
        'exp': 1700003600,
      };
      final jwt = _buildJwt(payload);

      final result = decodeJwtPayload(jwt);

      expect(result['iat'], 1700000000);
      expect(result['exp'], 1700003600);
    });

    test('handles payload with unicode characters', () {
      final payload = {'sub': 'u1', 'name': 'محمد', 'email': 'a@b.com'};
      final jwt = _buildJwt(payload);

      final result = decodeJwtPayload(jwt);

      expect(result['name'], 'محمد');
    });
  });
}
