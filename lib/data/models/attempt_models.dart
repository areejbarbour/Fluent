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

/// finish response (matches UserAttemptController::finish exactly):
/// {
///   "attempt_id": 1,
///   "score": 80,          // percentage 0–100
///   "passed": true,
///   "streak": { "current": 3, "increased": true },
///   "reward": {
///     "points_awarded": true,
///     "points": 50,
///     "user_level_id": 15|null,       // set on level pass
///     "certificate_url": "https..."|null
///   }
/// }
class FinishAttemptResult {
  final int attemptId;
  final int scorePercent;
  final bool passed;
  final FinishStreakResult streak;
  final FinishRewardResult reward;

  const FinishAttemptResult({
    required this.attemptId,
    required this.scorePercent,
    required this.passed,
    required this.streak,
    required this.reward,
  });

  factory FinishAttemptResult.fromJson(Map<String, dynamic> json) {
    final idRaw = json['attempt_id'];
    final scoreRaw = json['score'];
    final passedRaw = json['passed'];

    final streakRaw = json['streak'];
    final streakMap = streakRaw is Map
        ? Map<String, dynamic>.from(streakRaw)
        : <String, dynamic>{};

    final rewardRaw = json['reward'];
    final rewardMap = rewardRaw is Map
        ? Map<String, dynamic>.from(rewardRaw)
        : <String, dynamic>{};

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
      streak: FinishStreakResult.fromJson(streakMap),
      reward: FinishRewardResult.fromJson(rewardMap),
    );
  }
}

/// streak sub-object from finish:
/// { "current": 3, "increased": true }
class FinishStreakResult {
  final int current;
  final bool increased;

  const FinishStreakResult({required this.current, required this.increased});

  factory FinishStreakResult.fromJson(Map<String, dynamic> json) {
    final currentRaw = json['current'];
    final increasedRaw = json['increased'];
    return FinishStreakResult(
      current: currentRaw is int
          ? currentRaw
          : int.tryParse(currentRaw?.toString() ?? '') ?? 0,
      increased:
          increasedRaw == true ||
          increasedRaw == 1 ||
          increasedRaw?.toString() == 'true',
    );
  }
}

/// reward sub-object from UserAttemptController::finish:
/// {
///   "points_awarded": true,
///   "points": 50,
///   "user_level_id": 15|null,
///   "certificate_url": "https..."|null
/// }
///
/// On level pass the backend issues the certificate in AttemptService and
/// returns both fields. If generation failed, [certificateUrl] is null while
/// [userLevelId] is still set — client should retry via
/// GET /api/user-levels/{userLevelId}/certificate.
class FinishRewardResult {
  final bool pointsAwarded;
  final int points;

  /// Pivot id of the completed UserLevel (level tests only).
  final int? userLevelId;

  /// Spatie media URL of the certificate image (may be null if generation failed).
  final String? certificateUrl;

  const FinishRewardResult({
    required this.pointsAwarded,
    required this.points,
    this.userLevelId,
    this.certificateUrl,
  });

  bool get hasCertificateUrl =>
      certificateUrl != null && certificateUrl!.trim().isNotEmpty;

  factory FinishRewardResult.fromJson(Map<String, dynamic> json) {
    final awardedRaw = json['points_awarded'];
    final pointsRaw = json['points'];

    final ulRaw = json['user_level_id'];
    int? userLevelId;
    if (ulRaw is int) {
      userLevelId = ulRaw;
    } else if (ulRaw != null) {
      userLevelId = int.tryParse(ulRaw.toString());
    }

    final urlRaw = json['certificate_url']?.toString().trim();
    final certificateUrl = (urlRaw == null || urlRaw.isEmpty) ? null : urlRaw;

    return FinishRewardResult(
      pointsAwarded:
          awardedRaw == true ||
          awardedRaw == 1 ||
          awardedRaw?.toString() == 'true',
      points: pointsRaw is int
          ? pointsRaw
          : int.tryParse(pointsRaw?.toString() ?? '') ?? 0,
      userLevelId: userLevelId,
      certificateUrl: certificateUrl,
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
