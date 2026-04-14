import 'keyword_selection_record.dart';

class SessionResultPayload {
  final String? pages;
  final int? surah;
  final int durationSecs;
  final List<KeywordSelectionRecord> keywords;

  const SessionResultPayload({
    this.pages,
    this.surah,
    required this.durationSecs,
    required this.keywords,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (pages != null) {
      map['pages'] = pages;
    }
    if (surah != null) {
      map['surah'] = surah;
    }
    map['durationSecs'] = durationSecs;
    map['keywords'] = keywords.map((k) => k.toJson()).toList();
    return map;
  }

  factory SessionResultPayload.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('keywords') || json['keywords'] == null) {
      throw FormatException('Missing required field: keywords');
    }
    if (!json.containsKey('durationSecs') || json['durationSecs'] == null) {
      throw FormatException('Missing required field: durationSecs');
    }

    return SessionResultPayload(
      pages: json['pages'] as String?,
      surah: json['surah'] as int?,
      durationSecs: json['durationSecs'] as int,
      keywords: (json['keywords'] as List)
          .map((e) => KeywordSelectionRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
