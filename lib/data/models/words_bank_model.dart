class WordsBankItem {
  final int id;
  final String lessonTitle;
  final WordDetail word;
  final String status;
  final String? addedAt;

  WordsBankItem({
    required this.id,
    required this.lessonTitle,
    required this.word,
    required this.status,
    this.addedAt,
  });

  factory WordsBankItem.fromJson(Map<String, dynamic> json) {
    return WordsBankItem(
      id: json['id'] ?? 0,
      lessonTitle: json['lesson_title']?.toString() ?? '',
      word: WordDetail.fromJson(Map<String, dynamic>.from(json['word'] ?? {})),
      status: json['status']?.toString() ?? 'learning',
      addedAt: json['added_at']?.toString(),
    );
  }

  bool get isLearning => status.toLowerCase() == 'learning';

  bool get isMastered =>
      status.toLowerCase() == 'know' ||
      status.toLowerCase() == 'known' ||
      status.toLowerCase() == 'mastered';
}

class WordDetail {
  final int id;
  final int? lessonId;
  final String wordEn;
  final String wordAr;
  final String? audio;

  WordDetail({
    required this.id,
    this.lessonId,
    required this.wordEn,
    required this.wordAr,
    this.audio,
  });

  factory WordDetail.fromJson(Map<String, dynamic> json) {
    return WordDetail(
      id: json['id'] ?? 0,
      lessonId: json['lesson_id'],
      wordEn: json['word_en']?.toString() ?? '',
      wordAr: json['word_ar']?.toString() ?? '',
      audio: json['audio']?.toString(),
    );
  }

  bool get hasAudio => audio != null && audio!.trim().isNotEmpty;
}
