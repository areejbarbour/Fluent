import 'package:fluent/data/models/question_model.dart';

/// Parsed start response:
/// {
///   "attempt_id": 12,
///   "test": { StudentTestResource }
/// }
class AttemptStartResult {
  final int attemptId;
  final StudentTestSnapshot test;

  const AttemptStartResult({required this.attemptId, required this.test});

  factory AttemptStartResult.fromJson(Map<String, dynamic> json) {
    final testRaw = json['test'];
    final testMap = testRaw is Map
        ? Map<String, dynamic>.from(testRaw)
        : <String, dynamic>{};

    final attemptRaw = json['attempt_id'];
    final attemptId = attemptRaw is int
        ? attemptRaw
        : int.tryParse(attemptRaw?.toString() ?? '') ?? 0;

    return AttemptStartResult(
      attemptId: attemptId,
      test: StudentTestSnapshot.fromJson(testMap),
    );
  }
}

/// StudentTestResource shape from backend.
class StudentTestSnapshot {
  final int id;
  final String title;
  final int passingScore;

  /// e.g. "placement_test" | "lesson" | "course" | "level"
  final String type;
  final List<Question> questions;

  const StudentTestSnapshot({
    required this.id,
    required this.title,
    required this.passingScore,
    required this.type,
    required this.questions,
  });

  factory StudentTestSnapshot.fromJson(Map<String, dynamic> json) {
    final list = <Question>[];
    final raw = json['questions'];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          list.add(Question.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final idRaw = json['id'];
    final passRaw = json['passing_score'];

    return StudentTestSnapshot(
      id: idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '') ?? 0,
      title: json['title']?.toString() ?? '',
      passingScore: passRaw is int
          ? passRaw
          : int.tryParse(passRaw?.toString() ?? '') ?? 0,
      type: json['type']?.toString().toLowerCase().trim() ?? '',
      questions: list,
    );
  }

  bool get isPlacement => type.contains('placement');
  bool get isCourse => type.contains('course');
  bool get isLesson => type.contains('lesson');
  bool get isLevel => type.contains('level') && !type.contains('placement');
}

/// submitAnswer response body is awkwardly wrapped as a JSON array:
/// [ { "answer": {...}, "score": 2, "max_score": 2, "is_correct": true } ]
class SubmitAnswerResult {
  final int score;
  final int maxScore;
  final bool isCorrect;
  final Map<String, dynamic>? rawAnswer;

  /// Present when backend returns `correct_answer` on submit (recommended when wrong).
  final dynamic correctAnswer;

  const SubmitAnswerResult({
    required this.score,
    required this.maxScore,
    required this.isCorrect,
    this.rawAnswer,
    this.correctAnswer,
  });

  factory SubmitAnswerResult.fromResponse(dynamic data) {
    Map<String, dynamic>? map;

    if (data is List && data.isNotEmpty && data.first is Map) {
      map = Map<String, dynamic>.from(data.first as Map);
    } else if (data is Map) {
      // tolerate future keyed shape
      final inner = data['data'] ?? data;
      if (inner is Map) {
        map = Map<String, dynamic>.from(inner);
      }
    }

    map ??= <String, dynamic>{};

    final scoreRaw = map['score'];
    final maxRaw = map['max_score'];
    final correctRaw = map['is_correct'];

    return SubmitAnswerResult(
      score: scoreRaw is int
          ? scoreRaw
          : int.tryParse(scoreRaw?.toString() ?? '') ?? 0,
      maxScore: maxRaw is int
          ? maxRaw
          : int.tryParse(maxRaw?.toString() ?? '') ?? 0,
      isCorrect:
          correctRaw == true ||
          correctRaw == 1 ||
          correctRaw?.toString() == 'true',
      rawAnswer: map['answer'] is Map
          ? Map<String, dynamic>.from(map['answer'] as Map)
          : null,
      correctAnswer: map['correct_answer'],
    );
  }
}

/// finish response:
/// { "attempt_id": 1, "score": 80, "passed": true }
/// Note: score is percentage (0–100), not sum of points.
class FinishAttemptResult {
  final int attemptId;
  final int scorePercent;
  final bool passed;

  const FinishAttemptResult({
    required this.attemptId,
    required this.scorePercent,
    required this.passed,
  });

  factory FinishAttemptResult.fromJson(Map<String, dynamic> json) {
    final idRaw = json['attempt_id'];
    final scoreRaw = json['score'];
    final passedRaw = json['passed'];

    return FinishAttemptResult(
      attemptId: idRaw is int
          ? idRaw
          : int.tryParse(idRaw?.toString() ?? '') ?? 0,
      scorePercent: scoreRaw is int
          ? scoreRaw
          : int.tryParse(scoreRaw?.toString() ?? '') ?? 0,
      passed:
          passedRaw == true ||
          passedRaw == 1 ||
          passedRaw?.toString() == 'true',
    );
  }
}

/// review response (only if passed + completed):
/// {
///   "attempt_id": 1,
///   "total_score": 80,
///   "wrong_answers": [ { question_id, question_text, type, submitted_answer, correct_answer, score, max_score } ]
/// }
class ReviewAttemptResult {
  final int attemptId;
  final int totalScore;
  final List<ReviewWrongAnswer> wrongAnswers;

  const ReviewAttemptResult({
    required this.attemptId,
    required this.totalScore,
    required this.wrongAnswers,
  });

  factory ReviewAttemptResult.fromJson(Map<String, dynamic> json) {
    final list = <ReviewWrongAnswer>[];
    final raw = json['wrong_answers'];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          list.add(ReviewWrongAnswer.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final idRaw = json['attempt_id'];
    final scoreRaw = json['total_score'];

    return ReviewAttemptResult(
      attemptId: idRaw is int
          ? idRaw
          : int.tryParse(idRaw?.toString() ?? '') ?? 0,
      totalScore: scoreRaw is int
          ? scoreRaw
          : int.tryParse(scoreRaw?.toString() ?? '') ?? 0,
      wrongAnswers: list,
    );
  }
}

class ReviewWrongAnswer {
  final int questionId;
  final String questionText;
  final String type;
  final dynamic submittedAnswer;
  final dynamic correctAnswer;
  final int score;
  final int maxScore;

  const ReviewWrongAnswer({
    required this.questionId,
    required this.questionText,
    required this.type,
    required this.submittedAnswer,
    required this.correctAnswer,
    required this.score,
    required this.maxScore,
  });

  factory ReviewWrongAnswer.fromJson(Map<String, dynamic> json) {
    final qid = json['question_id'];
    final sc = json['score'];
    final mx = json['max_score'];
    return ReviewWrongAnswer(
      questionId: qid is int ? qid : int.tryParse(qid?.toString() ?? '') ?? 0,
      questionText: json['question_text']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      submittedAnswer: json['submitted_answer'],
      correctAnswer: json['correct_answer'],
      score: sc is int ? sc : int.tryParse(sc?.toString() ?? '') ?? 0,
      maxScore: mx is int ? mx : int.tryParse(mx?.toString() ?? '') ?? 0,
    );
  }
}
