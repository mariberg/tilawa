import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

class LevelService {
  final AuthService _authService;
  String? _currentLevel;

  LevelService({required AuthService authService})
      : _authService = authService;

  /// Returns the currently cached Arabic level, or null if not set.
  String? get currentLevel => _currentLevel;

  /// Fetches the user's Arabic level from the backend.
  /// Returns the level string or null if none is set.
  /// On HTTP failure, returns null (treat as no level).
  Future<String?> fetchLevel({http.Client? client}) async {
    final baseUrl = dotenv.env['BASE_URL'];
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception('BASE_URL is not configured');
    }

    final apiKey = dotenv.env['API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API_KEY is not configured');
    }

    final url = '$baseUrl/settings';
    final authHeaders = await _authService.getAuthHeaders();
    final headers = {
      ...authHeaders,
      'x-api-key': apiKey,
    };

    final httpClient = client ?? http.Client();
    try {
      final response = await httpClient.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode != 200) {
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final level = json['arabicLevel'] as String?;
      _currentLevel = level;
      return level;
    } catch (e) {
      return null;
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  /// Saves or updates the user's Arabic level via the backend.
  /// Validates that level is one of 'beginner', 'intermediate', 'advanced'.
  /// Updates _currentLevel on success. Throws on failure.
  Future<void> saveLevel(String level, {http.Client? client}) async {
    const validLevels = ['beginner', 'intermediate', 'advanced'];
    if (!validLevels.contains(level)) {
      throw ArgumentError('Invalid level value: $level');
    }

    final baseUrl = dotenv.env['BASE_URL'];
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception('BASE_URL is not configured');
    }

    final apiKey = dotenv.env['API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API_KEY is not configured');
    }

    final url = '$baseUrl/settings';
    final encodedBody = jsonEncode({'arabicLevel': level});
    final authHeaders = await _authService.getAuthHeaders();
    final headers = {
      'Content-Type': 'application/json',
      ...authHeaders,
      'x-api-key': apiKey,
    };

    final httpClient = client ?? http.Client();
    try {
      final response = await httpClient.put(
        Uri.parse(url),
        headers: headers,
        body: encodedBody,
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Save level failed: status ${response.statusCode}');
      }

      _currentLevel = level;
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }
}
