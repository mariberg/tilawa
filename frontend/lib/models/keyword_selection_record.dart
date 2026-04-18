class KeywordSelectionRecord {
  static const validStatuses = {'known', 'not_known'};

  final String arabic;
  final String translation;
  final String status;

  const KeywordSelectionRecord({
    required this.arabic,
    required this.translation,
    required this.status,
  }) : assert(status == 'known' || status == 'not_known');

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

    final status = json['status'] as String;
    if (!validStatuses.contains(status)) {
      throw FormatException('Invalid status: $status');
    }

    return KeywordSelectionRecord(
      arabic: json['arabic'] as String,
      translation: json['translation'] as String,
      status: status,
    );
  }

  Map<String, dynamic> toJson() => {
        'arabic': arabic,
        'translation': translation,
        'status': status,
      };
}
