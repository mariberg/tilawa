import 'dart:convert';
import 'dart:math';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../utils/jwt_utils.dart';

class AuthService {
  // --- Mock authentication code (replaced by OAuth2 authentication) ---
  // static const List<String> validUsers = [
  //   'demo-user-1',
  //   'demo-user-2',
  //   'demo-user-3',
  // ];
  //
  // static const String defaultUser = 'demo-user-1';
  //
  // String _currentUser = defaultUser;
  //
  // String get currentUser => _currentUser;
  //
  // /// Validates username/password against .env credentials.
  // /// Returns true if a match is found, false otherwise.
  // bool validate(String username, String password) {
  //   for (int i = 1; i <= 3; i++) {
  //     final envUser = dotenv.env['LOGIN_USER_$i'] ?? '';
  //     final envPass = dotenv.env['LOGIN_PASS_$i'] ?? '';
  //     if (username == envUser && password == envPass) {
  //       return true;
  //     }
  //   }
  //   return false;
  // }
  //
  // void setUser(String userId) {
  //   if (!validUsers.contains(userId)) {
  //     throw ArgumentError('Invalid user: $userId');
  //   }
  //   _currentUser = userId;
  // }
  //
  // String getAuthHeader() => 'Bearer $_currentUser';
  // --- End mock authentication code ---

  // --- OAuth2 configuration (read from .env) ---
  late final String _tokenHost;
  late final String _clientId;
  late final String _clientSecret;
  late final String _scopes;

  // --- Token storage ---
  String? _accessToken;
  String? _idToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;

  // --- User profile (decoded from JWT id_token) ---
  Map<String, dynamic>? _userProfile;

  // --- CSRF state ---
  String? _pendingState;

  // --- HTTP client (injectable for testing) ---
  final http.Client _httpClient;

  AuthService({http.Client? client}) : _httpClient = client ?? http.Client() {
    _tokenHost = dotenv.env['TOKEN_HOST'] ?? '';
    _clientId = dotenv.env['CLIENT_ID'] ?? '';
    _clientSecret = dotenv.env['CLIENT_SECRET'] ?? '';
    _scopes = dotenv.env['SCOPES'] ?? '';
  }

  bool get isAuthenticated => _accessToken != null && _tokenExpiry != null;
  Map<String, dynamic>? get userProfile => _userProfile;

  /// Builds the OAuth2 authorization URL and generates a CSRF state parameter.
  /// The state is persisted in browser sessionStorage so it survives the
  /// redirect back from the OAuth2 provider.
  ({String url, String state}) buildAuthorizationUrl(String redirectUri) {
    // Generate cryptographically random state for CSRF protection
    final random = Random.secure();
    final stateBytes = List<int>.generate(32, (_) => random.nextInt(256));
    final state = base64Url.encode(stateBytes);
    _pendingState = state;

    // Persist state in sessionStorage so it survives the browser redirect
    html.window.sessionStorage['oauth_state'] = state;

    final uri = Uri.parse('$_tokenHost/oauth2/auth').replace(
      queryParameters: {
        'client_id': _clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': _scopes,
        'state': state,
        'prompt': 'login',
      },
    );

    return (url: uri.toString(), state: state);
  }

  /// Handles the OAuth2 callback: verifies state, exchanges code for tokens,
  /// decodes the JWT id_token for user profile.
  Future<void> handleCallback(String code, String state, String redirectUri) async {
    // Restore CSRF state from sessionStorage (survives browser redirect)
    _pendingState ??= html.window.sessionStorage['oauth_state'];
    html.window.sessionStorage.remove('oauth_state');

    // Verify CSRF state
    if (state != _pendingState) {
      throw Exception('Authentication failed: invalid state');
    }

    // Exchange authorization code for tokens via backend proxy
    final baseUrl = dotenv.env['BASE_URL'] ?? '';
    final apiKey = dotenv.env['API_KEY'] ?? '';
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/oauth2/token'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'x-api-key': apiKey,
      },
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
        'client_id': _clientId,
        'client_secret': _clientSecret,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Authentication failed: could not exchange code for tokens');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    // Store tokens
    _accessToken = data['access_token'] as String?;
    _idToken = data['id_token'] as String?;
    _refreshToken = data['refresh_token'] as String?;
    final expiresIn = data['expires_in'] as int?;
    if (expiresIn != null) {
      _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
    }

    // Decode id_token for user profile; leave _userProfile null on failure
    if (_idToken != null) {
      try {
        final payload = decodeJwtPayload(_idToken!);
        _userProfile = {
          'sub': payload['sub'],
          'name': payload['name'],
          'email': payload['email'],
        };
      } catch (_) {
        _userProfile = null;
      }
    }
  }

  /// Returns OAuth2 headers for API calls. Refreshes token if expired or
  /// within 60 seconds of expiry.
  /// Sends the access_token as Authorization: Bearer header.
  Future<Map<String, String>> getAuthHeaders() async {
    if (_tokenExpiry != null &&
        _tokenExpiry!.difference(DateTime.now()).inSeconds <= 60) {
      await refreshAccessToken();
    }

    return {
      'Authorization': 'Bearer ${_accessToken ?? ''}',
    };
  }

  /// Refreshes the access token using the refresh token.
  /// On success, updates stored tokens and expiry.
  /// On failure, clears all tokens and user profile.
  Future<void> refreshAccessToken() async {
    final baseUrl = dotenv.env['BASE_URL'] ?? '';
    final apiKey = dotenv.env['API_KEY'] ?? '';
    final response = await _httpClient.post(
      Uri.parse('$baseUrl/oauth2/token'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'x-api-key': apiKey,
      },
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': _refreshToken ?? '',
        'client_id': _clientId,
        'client_secret': _clientSecret,
      },
    );

    if (response.statusCode != 200) {
      _accessToken = null;
      _idToken = null;
      _refreshToken = null;
      _tokenExpiry = null;
      _userProfile = null;
      return;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    _accessToken = data['access_token'] as String?;
    if (data.containsKey('id_token')) {
      _idToken = data['id_token'] as String?;
    }
    if (data.containsKey('refresh_token')) {
      _refreshToken = data['refresh_token'] as String?;
    }
    final expiresIn = data['expires_in'] as int?;
    if (expiresIn != null) {
      _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
    }
  }

  /// Clears all stored tokens and user profile, then returns the OAuth2
  /// provider logout URL with the id_token_hint for session termination.
  String logout(String postLogoutRedirectUri) {
    final idToken = _idToken;

    _accessToken = null;
    _idToken = null;
    _refreshToken = null;
    _tokenExpiry = null;
    _userProfile = null;

    final uri = Uri.parse('$_tokenHost/oauth2/sessions/logout').replace(
      queryParameters: {
        'post_logout_redirect_uri': postLogoutRedirectUri,
        'id_token_hint': idToken ?? '',
      },
    );

    return uri.toString();
  }
}
