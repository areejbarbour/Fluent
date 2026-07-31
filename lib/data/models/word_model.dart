class WordModel {
  final int id;
  final int lessonId;
  final String wordEn;
  final String wordAr;

  WordModel({
    required this.id,
    required this.lessonId,
    required this.wordEn,
    required this.wordAr,
  });

  factory WordModel.fromJson(Map<String, dynamic> json) {
    return WordModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      lessonId: json['lesson_id'] is int
          ? json['lesson_id'] as int
          : int.tryParse(json['lesson_id']?.toString() ?? '0') ?? 0,
      wordEn: json['word_en']?.toString() ?? '',
      wordAr: json['word_ar']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'lesson_id': lessonId,
        'word_en': wordEn,
        'word_ar': wordAr,
      };

  WordModel copyWith({
    int? id,
    int? lessonId,
    String? wordEn,
    String? wordAr,
  }) {
    return WordModel(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      wordEn: wordEn ?? this.wordEn,
      wordAr: wordAr ?? this.wordAr,
    );
  }

  /// Parse a list from lesson detail `words` field (WordResource collection).
  static List<WordModel> listFrom(dynamic raw) {
    if (raw == null) return const [];
    List list = const [];
    if (raw is List) {
      list = raw;
    } else if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      if (map['data'] is List) list = map['data'] as List;
    }
    return list
        .whereType<Map>()
        .map((e) => WordModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
