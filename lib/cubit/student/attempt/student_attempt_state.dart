import 'package:fluent/data/models/attempt_models.dart';
import 'package:fluent/data/models/question_model.dart';

abstract class StudentAttemptState {}

class StudentAttemptInitial extends StudentAttemptState {}

class StudentAttemptLoading extends StudentAttemptState {}

class StudentAttemptReady extends StudentAttemptState {}

class StudentAttemptStarting extends StudentAttemptState {}

class StudentAttemptInProgress extends StudentAttemptState {
  final int attemptId;
  final StudentTestSnapshot test;
  final int currentIndex;
  final bool submitting;
  final SubmitAnswerResult? lastSubmit;
  final String? inlineError;

  final Set<int> answeredQuestionIds;

  StudentAttemptInProgress({
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

  StudentAttemptInProgress copyWith({
    int? currentIndex,
    bool? submitting,
    SubmitAnswerResult? lastSubmit,
    String? inlineError,
    Set<int>? answeredQuestionIds,
    bool clearLastSubmit = false,
    bool clearInlineError = false,
  }) {
    return StudentAttemptInProgress(
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

class StudentAttemptFinishing extends StudentAttemptState {
  final int attemptId;
  final StudentTestSnapshot test;

  StudentAttemptFinishing({required this.attemptId, required this.test});
}

class StudentAttemptFinished extends StudentAttemptState {
  final FinishAttemptResult result;
  final StudentTestSnapshot test;
  final ReviewAttemptResult? review; 

  StudentAttemptFinished({
    required this.result,
    required this.test,
    this.review,
  });
}

class StudentAttemptLeft extends StudentAttemptState {
  final String message;

  StudentAttemptLeft([this.message = 'Attempt abandoned']);
}

class StudentAttemptFailure extends StudentAttemptState {
  final String message;
  final Map<String, dynamic>? errors;

  final bool isPlacementBlocked;

  StudentAttemptFailure(
    this.message, {
    this.errors,
    this.isPlacementBlocked = false,
  });
}
