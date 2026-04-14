class KeywordSelectionRecord {
  final String arabic;
  final String translation;
  final String status;

  const KeywordSelectionRecord({
    required this.arabic,
    required this.translation,
    required this.status,
  });

  factory KeywordSelectionRecord.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('arabic') || json['arabic'] == null) {
      throw FormatException('Missing required field: arabic');
    }
    if (!json.containsKey('translation') || json['translation'] == null) {
      throw FormatException('Missing required field: translation');
    }
    if (!json.containsKey('status') || json['status'] == null) {
      throw FormatException('Missing required field: status');
    }

    return KeywordSelectionRecord(
      arabic: json['arabic'] as String,
      translation: json['translation'] as String,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'arabic': arabic,
        'translation': translation,
        'status': status,
      };
}
