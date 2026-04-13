import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  static const List<String> validUsers = [
    'demo-user-1',
    'demo-user-2',
    'demo-user-3',
  ];

  static const String defaultUser = 'demo-user-1';

  String _currentUser = defaultUser;

  String get currentUser => _currentUser;

  /// Validates username/password against .env credentials.
  /// Returns true if a match is found, false otherwise.
  bool validate(String username, String password) {
    for (int i = 1; i <= 3; i++) {
      final envUser = dotenv.env['LOGIN_USER_$i'] ?? '';
      final envPass = dotenv.env['LOGIN_PASS_$i'] ?? '';
      if (username == envUser && password == envPass) {
        return true;
      }
    }
    return false;
  }

  void setUser(String userId) {
    if (!validUsers.contains(userId)) {
      throw ArgumentError('Invalid user: $userId');
    }
    _currentUser = userId;
  }

  String getAuthHeader() => 'Bearer $_currentUser';
}
