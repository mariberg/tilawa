import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/session_response.dart';
import '../models/session_result_payload.dart';
import 'auth_service.dart';

class SessionService {
  final AuthService _authService;

  SessionService({required AuthService authService})
      : _authService = authService;
  Future<SessionResponse> prepare({
    String? pages,
    String? surah,
    required String familiarity,
    http.Client? client,
  }) async {
    if (pages != null && surah != null) {
      throw ArgumentError('Only one of pages or surah is allowed');
    }
    if (pages == null && surah == null) {
      throw ArgumentError('Either pages or surah is required');
    }

    final baseUrl = dotenv.env['BASE_URL'];
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception('BASE_URL is not configured');
    }

    final apiKey = dotenv.env['API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API_KEY is not configured');
    }

    final body = <String, dynamic>{
      'familiarity': familiarity,
    };
    if (pages != null) {
      body['pages'] = pages;
    }
    if (surah != null) {
      body['surah'] = surah;
    }

    final url = '$baseUrl/sessions/prepare';
    final encodedBody = jsonEncode(body);
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': _authService.getAuthHeader(),
      'x-api-key': apiKey,
    };

    print('[SessionService] POST $url');
    print('[SessionService] Headers: ${headers.map((k, v) => MapEntry(k, k == 'x-api-key' ? '***' : v))}');
    print('[SessionService] Body: $encodedBody');

    final httpClient = client ?? http.Client();
    try {
      final response = await httpClient.post(
        Uri.parse(url),
        headers: headers,
        body: encodedBody,
      );

      print('[SessionService] Response status: ${response.statusCode}');
      print('[SessionService] Response headers: ${response.headers}');
      print('[SessionService] Response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
            'Session prepare failed: status ${response.statusCode}');
      }

      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return SessionResponse.fromJson(json);
      } on FormatException {
        rethrow;
      }
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  Future<String> submitResults({
    required SessionResultPayload payload,
    http.Client? client,
  }) async {
    final baseUrl = dotenv.env['BASE_URL'];
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception('BASE_URL is not configured');
    }

    final apiKey = dotenv.env['API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API_KEY is not configured');
    }

    final url = '$baseUrl/sessions';
    final encodedBody = jsonEncode(payload.toJson());
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': _authService.getAuthHeader(),
      'x-api-key': apiKey,
    };

    print('[SessionService] POST $url');
    print('[SessionService] Headers: ${headers.map((k, v) => MapEntry(k, k == 'x-api-key' ? '***' : v))}');
    print('[SessionService] Body: $encodedBody');

    final httpClient = client ?? http.Client();
    try {
      final response = await httpClient.post(
        Uri.parse(url),
        headers: headers,
        body: encodedBody,
      );

      print('[SessionService] Response status: ${response.statusCode}');
      print('[SessionService] Response headers: ${response.headers}');
      print('[SessionService] Response body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
            'Session submit failed: status ${response.statusCode}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['sessionId'] as String;
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  Future<void> submitFeeling({
    required String sessionId,
    required String feeling,
    http.Client? client,
  }) async {
    const validFeelings = ['smooth', 'struggled', 'revisit'];
    if (!validFeelings.contains(feeling)) {
      throw ArgumentError('Invalid feeling value: $feeling');
    }

    final baseUrl = dotenv.env['BASE_URL'];
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception('BASE_URL is not configured');
    }

    final apiKey = dotenv.env['API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API_KEY is not configured');
    }

    final url = '$baseUrl/sessions/$sessionId/feeling';
    final encodedBody = jsonEncode({'feeling': feeling});
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': _authService.getAuthHeader(),
      'x-api-key': apiKey,
    };

    print('[SessionService] PATCH $url');
    print('[SessionService] Headers: ${headers.map((k, v) => MapEntry(k, k == 'x-api-key' ? '***' : v))}');
    print('[SessionService] Body: $encodedBody');

    final httpClient = client ?? http.Client();
    try {
      final response = await httpClient.patch(
        Uri.parse(url),
        headers: headers,
        body: encodedBody,
      );

      print('[SessionService] Response status: ${response.statusCode}');
      print('[SessionService] Response headers: ${response.headers}');
      print('[SessionService] Response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
            'Submit feeling failed: status ${response.statusCode}');
      }
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }
}
