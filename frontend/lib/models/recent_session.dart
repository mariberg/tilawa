class RecentSession {
  final String sessionId;
  final String pages;
  final String feeling;
  final DateTime createdAt;

  const RecentSession({
    required this.sessionId,
    required this.pages,
    required this.feeling,
    required this.createdAt,
  });

  factory RecentSession.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('sessionId') || json['sessionId'] == null) {
      throw FormatException('Missing required field: sessionId');
    }
    if (!json.containsKey('pages') || json['pages'] == null) {
      throw FormatException('Missing required field: pages');
    }
    if (!json.containsKey('feeling') || json['feeling'] == null) {
      throw FormatException('Missing required field: feeling');
    }
    if (!json.containsKey('createdAt') || json['createdAt'] == null) {
      throw FormatException('Missing required field: createdAt');
    }

    return RecentSession(
      sessionId: json['sessionId'] as String,
      pages: json['pages'] as String,
      feeling: json['feeling'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'pages': pages,
      'feeling': feeling,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
