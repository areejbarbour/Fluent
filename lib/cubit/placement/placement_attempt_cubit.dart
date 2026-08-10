import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/data/models/attempt_models.dart';
import 'package:fluent/data/models/question_model.dart';
import 'package:fluent/data/models/question_type.dart';
import 'package:fluent/data/repository/attempt_repository.dart';
import 'package:fluent/helper/questions/answer_payload_helper.dart';
import 'placement_attempt_state.dart';

/// Full placement flow aligned with backend AttemptService:
/// startPlacementTest → submit-answer (sequential) → finish → review (if passed).
class PlacementAttemptCubit extends Cubit<PlacementAttemptState> {
  final AttemptRepository attemptRepository;

  PlacementAttemptCubit(this.attemptRepository)
    : super(PlacementAttemptInitial());

  int? _attemptId;
  StudentTestSnapshot? _test;
  final Set<int> _answered = {};

  // ── 1) Start ─────────────────────────────────────────────

  Future<void> startPlacement() async {
    emit(PlacementAttemptStarting());
    print('🟡 [PlacementAttemptCubit] Starting placement test...');

    final result = await attemptRepository.startPlacementTest();

    if (result['success'] == true && result['data'] is AttemptStartResult) {
      final data = result['data'] as AttemptStartResult;
      _attemptId = data.attemptId;
      _test = data.test;
      _answered.clear();

      if (data.test.questions.isEmpty) {
        emit(PlacementAttemptFailure('Placement test has no questions'));
        return;
      }

      print(
        '🎉 [PlacementAttemptCubit] attempt=${data.attemptId}, '
        'questions=${data.test.questions.length}',
      );

      emit(
        PlacementAttemptInProgress(
          attemptId: data.attemptId,
          test: data.test,
          currentIndex: 0,
          answeredQuestionIds: <int>{},
        ),
      );
    } else {
      final msg = result['message']?.toString() ?? 'Failed to start placement';
      final blocked =
          result['isPlacementBlocked'] == true ||
          msg.toLowerCase().contains('already taken') ||
          msg.toLowerCase().contains('cooldown') ||
          msg.toLowerCase().contains('placement');
      print('❌ [PlacementAttemptCubit] $msg');
      emit(
        PlacementAttemptFailure(
          msg,
          errors: result['errors'] as Map<String, dynamic>?,
          isPlacementBlocked: blocked,
        ),
      );
    }
  }

  // ── 2) Submit current question ───────────────────────────

  /// Generic entry — body already shaped by AnswerPayloadHelper.
  Future<bool> submitCurrent({required Map<String, dynamic> body}) async {
    final current = state;
    if (current is! PlacementAttemptInProgress) return false;
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
        '✅ [PlacementAttemptCubit] Q${q.id} score=${submit.score}/${submit.maxScore} '
        'correct=${submit.isCorrect}',
      );
      return true;
    }

    final msg = result['message']?.toString() ?? 'Failed to submit answer';
    emit(current.copyWith(submitting: false, inlineError: msg));
    print('❌ [PlacementAttemptCubit] submit failed: $msg');
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
    if (current is! PlacementAttemptInProgress) return;
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
      emit(PlacementAttemptFailure('No active attempt'));
      return;
    }

    emit(PlacementAttemptFinishing(attemptId: attemptId, test: test));
    print('🟡 [PlacementAttemptCubit] Finishing attempt $attemptId...');

    final result = await attemptRepository.finish(attemptId);

    if (result['success'] != true || result['data'] is! FinishAttemptResult) {
      final msg = result['message']?.toString() ?? 'Failed to finish attempt';
      emit(PlacementAttemptFailure(msg));
      return;
    }

    final finishData = result['data'] as FinishAttemptResult;
    print(
      '🎉 [PlacementAttemptCubit] score=${finishData.scorePercent}% '
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
      PlacementAttemptFinished(result: finishData, test: test, review: review),
    );
  }

  // ── 5) Leave (abandon) ───────────────────────────────────

  Future<void> leave() async {
    final attemptId = _attemptId;
    if (attemptId == null) {
      emit(PlacementAttemptLeft());
      return;
    }

    final result = await attemptRepository.leave(attemptId);
    _attemptId = null;
    _test = null;
    _answered.clear();

    if (result['success'] == true) {
      emit(PlacementAttemptLeft('Attempt abandoned'));
    } else {
      // Even on failure, clear local session so user can exit UI.
      emit(
        PlacementAttemptLeft(
          result['message']?.toString() ?? 'Attempt abandoned',
        ),
      );
    }
  }

  void reset() {
    _attemptId = null;
    _test = null;
    _answered.clear();
    emit(PlacementAttemptInitial());
  }
}
