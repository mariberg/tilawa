class KeywordModel {
  final String arabic;
  final String translation;
  final String hint;
  final String type;

  const KeywordModel({
    required this.arabic,
    required this.translation,
    required this.hint,
    required this.type,
  });

  factory KeywordModel.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('arabic') || json['arabic'] == null) {
      throw FormatException('Missing required field: arabic');
    }
    if (!json.containsKey('translation') || json['translation'] == null) {
      throw FormatException('Missing required field: translation');
    }
    if (!json.containsKey('hint') || json['hint'] == null) {
      throw FormatException('Missing required field: hint');
    }
    if (!json.containsKey('type') || json['type'] == null) {
      throw FormatException('Missing required field: type');
    }

    return KeywordModel(
      arabic: json['arabic'] as String,
      translation: json['translation'] as String,
      hint: json['hint'] as String,
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'arabic': arabic,
      'translation': translation,
      'hint': hint,
      'type': type,
    };
  }
}
