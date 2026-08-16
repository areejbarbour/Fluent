

class LessonFunnelItem {
  final int lessonId;
  final int order;
  final String title;
  final int reached;
  final int attemptedTest;

  const LessonFunnelItem({
    required this.lessonId,
    required this.order,
    required this.title,
    required this.reached,
    required this.attemptedTest,
  });

  factory LessonFunnelItem.fromJson(Map<String, dynamic> json) {
    return LessonFunnelItem(
      lessonId: _toInt(json['lesson_id']),
      order: _toInt(json['order']),
      title: json['title']?.toString() ?? '',
      reached: _toInt(json['reached']),
      attemptedTest: _toInt(json['attempted_test']),
    );
  }

  double get conversionRate {
    if (reached <= 0) return 0;
    return (attemptedTest / reached) * 100;
  }
}

class ScoreBucket {
  final String range; 
  final int count;

  const ScoreBucket({required this.range, required this.count});

  factory ScoreBucket.fromJson(Map<String, dynamic> json) {
    return ScoreBucket(
      range: json['range']?.toString() ?? '',
      count: _toInt(json['count']),
    );
  }
}

class QuestionStatItem {
  final int questionId;
  final String title;
  final String difficulty; 
  final double? avgScoreRatio;
  final double? errorRate;
  final int attemptsCount;
  final String? flag; 

  const QuestionStatItem({
    required this.questionId,
    required this.title,
    required this.difficulty,
    this.avgScoreRatio,
    this.errorRate,
    required this.attemptsCount,
    this.flag,
  });

  factory QuestionStatItem.fromJson(Map<String, dynamic> json) {
    return QuestionStatItem(
      questionId: _toInt(json['question_id']),
      title: json['title']?.toString() ?? '',
      difficulty: (json['difficulty']?.toString() ?? 'MEDIUM').toUpperCase(),
      avgScoreRatio: _toDoubleOrNull(json['avg_score_ratio']),
      errorRate: _toDoubleOrNull(json['error_rate']),
      attemptsCount: _toInt(json['attempts_count']),
      flag: json['flag']?.toString(),
    );
  }

  bool get hasFlag => flag != null && flag!.isNotEmpty;

  String get flagLabel {
    switch (flag) {
      case 'unexpected_high_error':
        return 'Unexpected high error';
      case 'unexpectedly_easy':
        return 'Unexpectedly easy';
      default:
        return flag ?? '';
    }
  }
}

class CourseStats {
  final double avgFirstAttemptPassRate;
  final double avgAbandonmentRate;
  final List<LessonFunnelItem> lessonsFunnel;

  const CourseStats({
    required this.avgFirstAttemptPassRate,
    required this.avgAbandonmentRate,
    required this.lessonsFunnel,
  });

  factory CourseStats.fromJson(Map<String, dynamic> json) {
    final funnelRaw = json['lessons_funnel'];
    final funnel = <LessonFunnelItem>[];
    if (funnelRaw is List) {
      for (final e in funnelRaw) {
        if (e is Map) {
          funnel.add(
            LessonFunnelItem.fromJson(Map<String, dynamic>.from(e)),
          );
        }
      }
    }

    return CourseStats(
      avgFirstAttemptPassRate: _toDouble(json['avg_first_attempt_pass_rate']),
      avgAbandonmentRate: _toDouble(json['avg_abandonment_rate']),
      lessonsFunnel: funnel,
    );
  }

  bool get hasData =>
      avgFirstAttemptPassRate > 0 ||
      avgAbandonmentRate > 0 ||
      lessonsFunnel.isNotEmpty;
}

class TestStats {
  final double firstAttemptPassRate;
  final double avgAttemptsToPass;
  final double abandonmentRate;
  final double currentlyStrugglingRate;
  final List<ScoreBucket> scoreDistribution;
  final List<QuestionStatItem> questions;

  const TestStats({
    required this.firstAttemptPassRate,
    required this.avgAttemptsToPass,
    required this.abandonmentRate,
    required this.currentlyStrugglingRate,
    required this.scoreDistribution,
    required this.questions,
  });

  factory TestStats.fromJson(Map<String, dynamic> json) {
    final distRaw = json['score_distribution'];
    final dist = <ScoreBucket>[];
    if (distRaw is List) {
      for (final e in distRaw) {
        if (e is Map) {
          dist.add(ScoreBucket.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }

    final qRaw = json['questions'];
    final qs = <QuestionStatItem>[];
    if (qRaw is List) {
      for (final e in qRaw) {
        if (e is Map) {
          qs.add(QuestionStatItem.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }

    return TestStats(
      firstAttemptPassRate: _toDouble(json['first_attempt_pass_rate']),
      avgAttemptsToPass: _toDouble(json['avg_attempts_to_pass']),
      abandonmentRate: _toDouble(json['abandonment_rate']),
      currentlyStrugglingRate: _toDouble(json['currently_struggling_rate']),
      scoreDistribution: dist,
      questions: qs,
    );
  }

  bool get hasData =>
      firstAttemptPassRate > 0 ||
      avgAttemptsToPass > 0 ||
      abandonmentRate > 0 ||
      currentlyStrugglingRate > 0 ||
      scoreDistribution.any((b) => b.count > 0) ||
      questions.isNotEmpty;
}

// ── helpers ──────────────────────────────────────────────────

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

double? _toDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}
