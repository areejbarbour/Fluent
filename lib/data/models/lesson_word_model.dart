class LessonWordModel {
  final int id;
  final int lessonId;
  final String wordEn;
  final String wordAr;
  final String? audio;

  LessonWordModel({
    required this.id,
    required this.lessonId,
    required this.wordEn,
    required this.wordAr,
    this.audio,
  });

  factory LessonWordModel.fromJson(Map<String, dynamic> json) {
    return LessonWordModel(
      id: json['id'] ?? 0,
      lessonId: json['lesson_id'] ?? 0,
      wordEn: json['word_en']?.toString() ?? '',
      wordAr: json['word_ar']?.toString() ?? '',
      audio: json['audio']?.toString(),
    );
  }

  bool get hasAudio => audio != null && audio!.trim().isNotEmpty;
}