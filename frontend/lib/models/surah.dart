class Surah {
  final int id;
  final String nameSimple;
  final String nameArabic;
  final String translation;

  const Surah({
    required this.id,
    required this.nameSimple,
    required this.nameArabic,
    required this.translation,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('id') || json['id'] == null) {
      throw FormatException('Missing required field: id');
    }
    if (!json.containsKey('name_simple') || json['name_simple'] == null) {
      throw FormatException('Missing required field: name_simple');
    }
    if (!json.containsKey('name_arabic') || json['name_arabic'] == null) {
      throw FormatException('Missing required field: name_arabic');
    }
    if (!json.containsKey('translated_name') ||
        json['translated_name'] == null) {
      throw FormatException('Missing required field: translated_name');
    }
    final translatedName = json['translated_name'];
    if (translatedName is! Map<String, dynamic> ||
        !translatedName.containsKey('name') ||
        translatedName['name'] == null) {
      throw FormatException('Missing required field: translated_name.name');
    }

    return Surah(
      id: json['id'] as int,
      nameSimple: json['name_simple'] as String,
      nameArabic: json['name_arabic'] as String,
      translation: translatedName['name'] as String,
    );
  }
}
