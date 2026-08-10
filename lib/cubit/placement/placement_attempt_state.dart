import 'package:fluent/data/models/attempt_models.dart';
import 'package:fluent/data/models/question_model.dart';

abstract class PlacementAttemptState {}

class PlacementAttemptInitial extends PlacementAttemptState {}

class PlacementAttemptLoading extends PlacementAttemptState {}

/// Intro ready — test not started yet (optional; we start on user confirm).
class PlacementAttemptReady extends PlacementAttemptState {}

class PlacementAttemptStarting extends PlacementAttemptState {}

/// Active in-progress session. Questions MUST be answered in order
/// (backend assertPreviousQuestionsAnswered).
class PlacementAttemptInProgress extends PlacementAttemptState {
  final int attemptId;
  final StudentTestSnapshot test;
  final int currentIndex;
  final bool submitting;
  final SubmitAnswerResult? lastSubmit;
  final String? inlineError;

  /// questionIds already submitted (cannot re-submit).
  final Set<int> answeredQuestionIds;

  PlacementAttemptInProgress({
    required this.attemptId,
    required this.test,
    required this.currentIndex,
    this.submitting = false,
    this.lastSubmit,
    this.inlineError,
    Set<int>? answeredQuestionIds,
  }) : answeredQuestionIds = answeredQuestionIds ?? <int>{};

  List<Question> get questions => test.questions;

  Question get currentQuestion => questions[currentIndex];

  bool get isLast => currentIndex >= questions.length - 1;

  bool get hasQuestions => questions.isNotEmpty;

  PlacementAttemptInProgress copyWith({
    int? currentIndex,
    bool? submitting,
    SubmitAnswerResult? lastSubmit,
    String? inlineError,
    Set<int>? answeredQuestionIds,
    bool clearLastSubmit = false,
    bool clearInlineError = false,
  }) {
    return PlacementAttemptInProgress(
      attemptId: attemptId,
      test: test,
      currentIndex: currentIndex ?? this.currentIndex,
      submitting: submitting ?? this.submitting,
      lastSubmit: clearLastSubmit ? null : (lastSubmit ?? this.lastSubmit),
      inlineError: clearInlineError ? null : (inlineError ?? this.inlineError),
      answeredQuestionIds: answeredQuestionIds ?? this.answeredQuestionIds,
    );
  }
}

class PlacementAttemptFinishing extends PlacementAttemptState {
  final int attemptId;
  final StudentTestSnapshot test;

  PlacementAttemptFinishing({required this.attemptId, required this.test});
}

class PlacementAttemptFinished extends PlacementAttemptState {
  final FinishAttemptResult result;
  final StudentTestSnapshot test;
  final ReviewAttemptResult? review; // null if failed or review not loaded

  PlacementAttemptFinished({
    required this.result,
    required this.test,
    this.review,
  });
}

class PlacementAttemptLeft extends PlacementAttemptState {
  final String message;

  PlacementAttemptLeft([this.message = 'Attempt abandoned']);
}

class PlacementAttemptFailure extends PlacementAttemptState {
  final String message;
  final Map<String, dynamic>? errors;

  /// If true, user already has levels / retake cooldown (backend rule).
  final bool isPlacementBlocked;

  PlacementAttemptFailure(
    this.message, {
    this.errors,
    this.isPlacementBlocked = false,
  });
}
