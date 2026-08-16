class WordModel {
  final int id;
  final int lessonId;
  final String wordEn;
  final String wordAr;

  final String? audio;

  WordModel({
    required this.id,
    required this.lessonId,
    required this.wordEn,
    required this.wordAr,
    this.audio,
  });

  factory WordModel.fromJson(Map<String, dynamic> json) {
    final rawAudio = json['audio']?.toString();
    return WordModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      lessonId: json['lesson_id'] is int
          ? json['lesson_id'] as int
          : int.tryParse(json['lesson_id']?.toString() ?? '0') ?? 0,
      wordEn: json['word_en']?.toString() ?? '',
      wordAr: json['word_ar']?.toString() ?? '',
      audio: (rawAudio != null && rawAudio.trim().isNotEmpty) ? rawAudio : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'lesson_id': lessonId,
    'word_en': wordEn,
    'word_ar': wordAr,
    if (audio != null) 'audio': audio,
  };

  WordModel copyWith({
    int? id,
    int? lessonId,
    String? wordEn,
    String? wordAr,
    String? audio,
    bool clearAudio = false,
  }) {
    return WordModel(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      wordEn: wordEn ?? this.wordEn,
      wordAr: wordAr ?? this.wordAr,
      audio: clearAudio ? null : (audio ?? this.audio),
    );
  }

  bool get hasAudio => audio != null && audio!.trim().isNotEmpty;

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
