import 'package:fluent/cubit/student/attempt/student_attempt_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/data/models/attempt_models.dart';
import 'package:fluent/data/repository/attempt_repository.dart';
import 'package:fluent/helper/questions/answer_payload_helper.dart';

/// Full placement flow aligned with backend AttemptService:
/// POST /tests/{id}/start → submit-answer (sequential) → finish → review (if passed).
/// Immediate feedback: lastSubmit.isCorrect after each submit.
class StudentAttemptCubit extends Cubit<StudentAttemptState> {
  final AttemptRepository attemptRepository;

  StudentAttemptCubit(this.attemptRepository) : super(StudentAttemptInitial());

  int? _attemptId;
  StudentTestSnapshot? _test;
  final Set<int> _answered = {};

  // ── 1) Start ─────────────────────────────────────────────

  /// Start a published test by id (lesson / course / …).
  /// Backend: POST /api/tests/{test}/start
  Future<void> start(int testId) async {
    emit(StudentAttemptStarting());
    print('🟡 [StudentAttemptCubit] Starting test $testId...');

    final result = await attemptRepository.startTest(testId);

    if (result['success'] != true || result['data'] is! AttemptStartResult) {
      final msg = result['message']?.toString() ?? 'Failed to start test';
      emit(StudentAttemptFailure(msg));
      print('❌ [StudentAttemptCubit] start failed: $msg');
      return;
    }

    final data = result['data'] as AttemptStartResult;
    _attemptId = data.attemptId;
    _test = data.test;
    _answered.clear();

    if (data.test.questions.isEmpty) {
      emit(StudentAttemptFailure('Test has no questions'));
      return;
    }

    print(
      '✅ [StudentAttemptCubit] attempt=${data.attemptId} '
      'questions=${data.test.questions.length} type=${data.test.type}',
    );

    emit(
      StudentAttemptInProgress(
        attemptId: data.attemptId,
        test: data.test,
        currentIndex: 0,
      ),
    );
  }

  // ── 2) Submit current question ───────────────────────────

  /// Generic entry — body already shaped by AnswerPayloadHelper.
  Future<bool> submitCurrent({required Map<String, dynamic> body}) async {
    final current = state;
    if (current is! StudentAttemptInProgress) return false;
    if (current.submitting) return false;

    final q = current.currentQuestion;
    if (_answered.contains(q.id)) {
      emit(
        current.copyWith(
          inlineError: 'This question has already been answered.',
        ),
      );
      return false;
    }

    emit(
      current.copyWith(
        submitting: true,
        clearInlineError: true,
        clearLastSubmit: true,
      ),
    );

    final result = await attemptRepository.submitAnswer(
      attemptId: current.attemptId,
      questionId: q.id,
      body: body,
    );

    if (result['success'] == true && result['data'] is SubmitAnswerResult) {
      final submit = result['data'] as SubmitAnswerResult;
      _answered.add(q.id);

      emit(
        current.copyWith(
          submitting: false,
          lastSubmit: submit,
          answeredQuestionIds: Set<int>.from(_answered),
          clearInlineError: true,
        ),
      );
      print(
        '✅ [StudentAttemptCubit] Q${q.id} score=${submit.score}/${submit.maxScore} '
        'correct=${submit.isCorrect}',
      );
      return true;
    }

    final msg = result['message']?.toString() ?? 'Failed to submit answer';
    emit(current.copyWith(submitting: false, inlineError: msg));
    print('❌ [StudentAttemptCubit] submit failed: $msg');
    return false;
  }

  Future<bool> submitMcq(int selectedAnswerId) {
    return submitCurrent(
      body: AnswerPayloadHelper.mcq(selectedAnswerId: selectedAnswerId),
    );
  }

  Future<bool> submitFill(Map<int, String> blankInputs) {
    return submitCurrent(
      body: AnswerPayloadHelper.fill(blankInputs: blankInputs),
    );
  }

  Future<bool> submitArrange(List<int> orderedIds) {
    return submitCurrent(
      body: AnswerPayloadHelper.arrange(orderedIds: orderedIds),
    );
  }

  Future<bool> submitPair(Map<int, int> matches) {
    return submitCurrent(body: AnswerPayloadHelper.pair(matches: matches));
  }

  // ── 3) Navigate (only after successful submit) ───────────

  /// Move to next question. Backend requires sequential answers —
  /// never skip ahead.
  void goNext() {
    final current = state;
    if (current is! StudentAttemptInProgress) return;
    if (!_answered.contains(current.currentQuestion.id)) return;

    if (current.isLast) {
      finish();
      return;
    }

    emit(
      current.copyWith(
        currentIndex: current.currentIndex + 1,
        clearLastSubmit: true,
        clearInlineError: true,
      ),
    );
  }

  // ── 4) Finish ────────────────────────────────────────────

  Future<void> finish() async {
    final attemptId = _attemptId;
    final test = _test;
    if (attemptId == null || test == null) {
      emit(StudentAttemptFailure('No active attempt'));
      return;
    }

    emit(StudentAttemptFinishing(attemptId: attemptId, test: test));
    print('🟡 [StudentAttemptCubit] Finishing attempt $attemptId...');

    final result = await attemptRepository.finish(attemptId);

    if (result['success'] != true || result['data'] is! FinishAttemptResult) {
      final msg = result['message']?.toString() ?? 'Failed to finish attempt';
      emit(StudentAttemptFailure(msg));
      return;
    }

    final finishData = result['data'] as FinishAttemptResult;
    print(
      '🎉 [StudentAttemptCubit] score=${finishData.scorePercent}% '
      'passed=${finishData.passed}',
    );

    ReviewAttemptResult? review;
    if (finishData.passed) {
      final reviewRes = await attemptRepository.review(attemptId);
      if (reviewRes['success'] == true &&
          reviewRes['data'] is ReviewAttemptResult) {
        review = reviewRes['data'] as ReviewAttemptResult;
      }
      // If review fails (edge case), still show finish result.
    }

    emit(
      StudentAttemptFinished(result: finishData, test: test, review: review),
    );
  }

  // ── 5) Leave (abandon) ───────────────────────────────────

  Future<void> leave() async {
    final attemptId = _attemptId;
    if (attemptId == null) {
      if (!isClosed) emit(StudentAttemptLeft());
      return;
    }

    final result = await attemptRepository.leave(attemptId);
    _attemptId = null;
    _test = null;
    _answered.clear();

    // UI may have already popped and closed this cubit — never emit after close.
    if (isClosed) return;

    if (result['success'] == true) {
      emit(StudentAttemptLeft('Attempt abandoned'));
    } else {
      emit(
        StudentAttemptLeft(
          result['message']?.toString() ?? 'Attempt abandoned',
        ),
      );
    }
  }

  void reset() {
    _attemptId = null;
    _test = null;
    _answered.clear();
    emit(StudentAttemptInitial());
  }
}
