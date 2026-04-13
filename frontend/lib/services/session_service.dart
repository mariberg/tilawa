import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/session_response.dart';

class SessionService {
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
      'Authorization': 'Bearer demo-user-1',
      'x-api-key': apiKey,
    };

    print('[SessionService] POST $url');
    print('[SessionService] Headers: $headers');
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
}
