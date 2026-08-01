import 'question_type.dart';

class QuestionAnswer {
  final int? id;
  final String? textAnswer;
  final bool? isCorrect;
  final int? order;
  final int? blankOrder;
  final String? leftText;
  final String? rightText;

  QuestionAnswer({
    this.id,
    this.textAnswer,
    this.isCorrect,
    this.order,
    this.blankOrder,
    this.leftText,
    this.rightText,
  });

  /// Backend often returns MySQL bool as 0/1 (int), not true/false.
  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.trim().toLowerCase();
      if (v == 'true' || v == '1') return true;
      if (v == 'false' || v == '0') return false;
    }
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  factory QuestionAnswer.fromJson(Map<String, dynamic> json) {
    return QuestionAnswer(
      id: _parseInt(json['id']),
      textAnswer: json['text_answer']?.toString(),
      isCorrect: _parseBool(json['is_correct']),
      order: _parseInt(json['order']),
      blankOrder: _parseInt(json['blank_order']),
      leftText: json['left_text']?.toString(),
      rightText: json['right_text']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (id != null) map['id'] = id;
    if (textAnswer != null) map['text_answer'] = textAnswer;
    if (isCorrect != null) map['is_correct'] = isCorrect;
    if (order != null) map['order'] = order;
    if (blankOrder != null) map['blank_order'] = blankOrder;
    if (leftText != null) map['left_text'] = leftText;
    if (rightText != null) map['right_text'] = rightText;
    return map;
  }

  QuestionAnswer copyWith({
    int? id,
    String? textAnswer,
    bool? isCorrect,
    int? order,
    int? blankOrder,
    String? leftText,
    String? rightText,
  }) {
    return QuestionAnswer(
      id: id ?? this.id,
      textAnswer: textAnswer ?? this.textAnswer,
      isCorrect: isCorrect ?? this.isCorrect,
      order: order ?? this.order,
      blankOrder: blankOrder ?? this.blankOrder,
      leftText: leftText ?? this.leftText,
      rightText: rightText ?? this.rightText,
    );
  }
}

class Question {
  final int id;
  final int userId;
  final QuestionType type;
  final String titleQuestionEn;
  final String titleQuestionAr;
  final String? textQuestion;
  final QuestionDifficulty difficulty;
  final int score;
  final int? previousQuestionId;
  final List<QuestionAnswer> answers;
  final String? audioUrl;
  final String? imageUrl;
  final bool hasNextVersion;
  final bool? isEligible;

  Question({
    required this.id,
    required this.userId,
    required this.type,
    required this.titleQuestionEn,
    required this.titleQuestionAr,
    this.textQuestion,
    required this.difficulty,
    required this.score,
    this.previousQuestionId,
    this.answers = const [],
    this.audioUrl,
    this.imageUrl,
    this.hasNextVersion = false,
    this.isEligible,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    final answersJson = json['answers'];
    final answers = <QuestionAnswer>[];
    if (answersJson is List) {
      for (final a in answersJson) {
        if (a is Map<String, dynamic>) {
          answers.add(QuestionAnswer.fromJson(a));
        }
      }
    }

    // media can be: string url, array of {url, ...}, or null
    String? audioUrl = json['audio_url']?.toString();
    String? imageUrl = json['image_url']?.toString();
    if (audioUrl == null && json['audio'] is String) {
      audioUrl = json['audio'];
    } else if (audioUrl == null &&
        json['audio'] is List &&
        (json['audio'] as List).isNotEmpty) {
      final first = (json['audio'] as List).first;
      if (first is Map && first['url'] != null)
        audioUrl = first['url'].toString();
    } else if (audioUrl == null &&
        json['audio'] is Map &&
        (json['audio'] as Map)['url'] != null) {
      audioUrl = (json['audio'] as Map)['url'].toString();
    }
    if (imageUrl == null && json['image'] is String) {
      imageUrl = json['image'];
    } else if (imageUrl == null &&
        json['image'] is List &&
        (json['image'] as List).isNotEmpty) {
      final first = (json['image'] as List).first;
      if (first is Map && first['url'] != null)
        imageUrl = first['url'].toString();
    } else if (imageUrl == null &&
        json['image'] is Map &&
        (json['image'] as Map)['url'] != null) {
      imageUrl = (json['image'] as Map)['url'].toString();
    }
    if (audioUrl != null && audioUrl.trim().isEmpty) audioUrl = null;
    if (imageUrl != null && imageUrl.trim().isEmpty) imageUrl = null;

    return Question(
      id: json['id'] is int ? json['id'] : 0,
      userId: json['user_id'] is int ? json['user_id'] : 0,
      type: QuestionType.fromString(json['type']?.toString()),
      titleQuestionEn: json['title_question_en']?.toString() ?? '',
      titleQuestionAr: json['title_question_ar']?.toString() ?? '',
      textQuestion: json['text_question']?.toString(),
      difficulty: QuestionDifficulty.fromString(json['difficulty']?.toString()),
      score: json['score'] is int ? json['score'] : 0,
      previousQuestionId: json['previous_question_id'] is int
          ? json['previous_question_id']
          : null,
      answers: answers,
      audioUrl: audioUrl,
      imageUrl: imageUrl,
      // ✅ FIX #3: الباك ما يرجع `next_version`، نعتمد على previous_question_id
      // لو السؤال عنده parent، يعني هو نسخة جديدة (next version of someone)
      hasNextVersion:
          json['has_next_version'] == true || json['next_version'] != null,
      isEligible: json['is_eligible'] is bool
          ? json['is_eligible'] as bool
          : null,
    );
  }
}
