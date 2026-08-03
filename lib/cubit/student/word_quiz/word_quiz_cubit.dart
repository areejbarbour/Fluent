import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/data/models/word_quiz_model.dart';
import 'package:fluent/data/repository/word_quiz_repository.dart';
import 'word_quiz_state.dart';

/// Student word quiz (matches backend StudentWordService).
///
/// - loadQuiz: GET /api/words/quiz
/// - selectOption: local UI selection
/// - submitAnswer: POST /api/words/{word}/quiz_check { answer_id }
/// - nextQuestion / finish
class WordQuizCubit extends Cubit<WordQuizState> {
  final WordQuizRepository repository;

  WordQuizCubit(this.repository) : super(const WordQuizInitial());

  Future<void> loadQuiz() async {
    emit(const WordQuizLoading());
    print('🟡 [WordQuizCubit] Loading quiz...');

    final result = await repository.getQuiz();
    if (result['success'] != true) {
      emit(
        WordQuizFailure(result['message']?.toString() ?? 'Failed to load quiz'),
      );
      return;
    }

    final questions = (result['data'] as List<WordQuizQuestion>?) ?? [];
    if (questions.isEmpty) {
      emit(const WordQuizEmpty());
      return;
    }

    print('🎉 [WordQuizCubit] Loaded ${questions.length} questions');
    emit(WordQuizInProgress(questions: questions, currentIndex: 0));
  }

  void selectOption(int optionId) {
    final s = state;
    if (s is! WordQuizInProgress) return;
    if (s.hasAnswered || s.isChecking) return;
    emit(s.copyWith(selectedOptionId: optionId));
  }

  Future<void> submitAnswer() async {
    final s = state;
    if (s is! WordQuizInProgress) return;
    if (s.selectedOptionId == null || s.hasAnswered || s.isChecking) return;

    emit(s.copyWith(isChecking: true));
    final wordId = s.current.wordId;
    final answerId = s.selectedOptionId!;

    print('🟡 [WordQuizCubit] Checking word #$wordId answer #$answerId');
    final result = await repository.checkAnswer(
      wordId: wordId,
      answerId: answerId,
    );

    if (result['success'] == true && result['data'] is WordQuizCheckResult) {
      final check = result['data'] as WordQuizCheckResult;
      emit(
        s.copyWith(
          isChecking: false,
          lastResult: check,
          correctCount: check.correct ? s.correctCount + 1 : s.correctCount,
          wrongCount: check.correct ? s.wrongCount : s.wrongCount + 1,
        ),
      );
    } else {
      emit(s.copyWith(isChecking: false));
      // Surface error but stay on same question
      emit(
        WordQuizFailure(
          result['message']?.toString() ?? 'Failed to check answer',
        ),
      );
      // Restore in-progress so user can retry
      emit(s.copyWith(isChecking: false));
    }
  }

  void nextQuestion() {
    final s = state;
    if (s is! WordQuizInProgress) return;
    if (!s.hasAnswered) return;

    if (s.isLast) {
      emit(
        WordQuizFinished(
          total: s.total,
          correctCount: s.correctCount,
          wrongCount: s.wrongCount,
        ),
      );
      return;
    }

    emit(
      s.copyWith(
        currentIndex: s.currentIndex + 1,
        clearSelection: true,
        clearResult: true,
        isChecking: false,
      ),
    );
  }

  void restart() => loadQuiz();
}
