class RecentSession {
  final String sessionId;
  final String? pages;
  final int? surah;
  final String? feeling;
  final DateTime createdAt;

  const RecentSession({
    required this.sessionId,
    this.pages,
    this.surah,
    this.feeling,
    required this.createdAt,
  });

  factory RecentSession.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('sessionId') || json['sessionId'] == null) {
      throw FormatException('Missing required field: sessionId');
    }
    if (!json.containsKey('createdAt') || json['createdAt'] == null) {
      throw FormatException('Missing required field: createdAt');
    }

    final pages = json['pages'] as String?;
    final surah = json['surah'] as int?;

    if (pages == null && surah == null) {
      throw FormatException('Either pages or surah must be present');
    }

    final rawFeeling = json['feeling'] as String?;
    final feeling = (rawFeeling == 'null') ? null : rawFeeling;

    return RecentSession(
      sessionId: json['sessionId'] as String,
      pages: pages,
      surah: surah,
      feeling: feeling,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      if (pages != null) 'pages': pages,
      if (surah != null) 'surah': surah,
      if (feeling != null) 'feeling': feeling,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
