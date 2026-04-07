import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/surah.dart';

class SurahService {
  static const String _baseUrl = 'https://api.quran.com/api/v4/chapters';
  List<Surah>? _cachedSurahs;

  Future<List<Surah>> fetchSurahs({http.Client? client}) async {
    if (_cachedSurahs != null) {
      return _cachedSurahs!;
    }

    final httpClient = client ?? http.Client();
    try {
      final response = await httpClient.get(Uri.parse(_baseUrl));

      if (response.statusCode != 200) {
        throw Exception('Failed to load surahs: status ${response.statusCode}');
      }

      final decoded = json.decode(response.body);
      final List<dynamic> chapters =
          decoded is List ? decoded : (decoded as Map<String, dynamic>)['chapters'];
      final surahs = chapters
          .map((json) => Surah.fromJson(json as Map<String, dynamic>))
          .toList();

      _cachedSurahs = surahs;
      return surahs;
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }
}
