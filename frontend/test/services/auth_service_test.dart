import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:quran_prep/services/auth_service.dart';

void main() {
  setUpAll(() async {
    await dotenv.load(fileName: '.env');
  });

  group('AuthService.validate', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService();
    });

    test('returns true for valid demo-user-1 credentials', () {
      expect(authService.validate('demo-user-1', 'test'), isTrue);
    });

    test('returns true for valid demo-user-2 credentials', () {
      expect(authService.validate('demo-user-2', 'Password1234#'), isTrue);
    });

    test('returns true for valid demo-user-3 credentials', () {
      expect(authService.validate('demo-user-3', 'Password1234#'), isTrue);
    });

    test('returns false for wrong password', () {
      expect(authService.validate('demo-user-1', 'wrong'), isFalse);
    });

    test('returns false for wrong username', () {
      expect(authService.validate('unknown', 'test'), isFalse);
    });

    test('returns false for empty credentials', () {
      expect(authService.validate('', ''), isFalse);
    });

    test('returns false for swapped credentials', () {
      expect(authService.validate('test', 'demo-user-1'), isFalse);
    });
  });

  group('AuthService.setUser', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService();
    });

    test('sets user for valid user id', () {
      authService.setUser('demo-user-2');
      expect(authService.currentUser, 'demo-user-2');
    });

    test('throws for invalid user id', () {
      expect(() => authService.setUser('invalid'), throwsArgumentError);
    });
  });

  group('AuthService.getAuthHeader', () {
    test('returns Bearer token with current user', () {
      final authService = AuthService();
      authService.setUser('demo-user-3');
      expect(authService.getAuthHeader(), 'Bearer demo-user-3');
    });
  });
}
