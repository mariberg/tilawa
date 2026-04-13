import 'keyword_model.dart';

class SessionResponse {
  final String sessionId;
  final List<String> overview;
  final List<KeywordModel> keywords;

  const SessionResponse({
    required this.sessionId,
    required this.overview,
    required this.keywords,
  });

  factory SessionResponse.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('sessionId') || json['sessionId'] == null) {
      throw FormatException('Missing required field: sessionId');
    }
    if (!json.containsKey('overview') || json['overview'] == null) {
      throw FormatException('Missing required field: overview');
    }
    if (!json.containsKey('keywords') || json['keywords'] == null) {
      throw FormatException('Missing required field: keywords');
    }

    return SessionResponse(
      sessionId: json['sessionId'] as String,
      overview: List<String>.from(json['overview'] as List),
      keywords: (json['keywords'] as List)
          .map((e) => KeywordModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'overview': overview,
      'keywords': keywords.map((k) => k.toJson()).toList(),
    };
  }
}
