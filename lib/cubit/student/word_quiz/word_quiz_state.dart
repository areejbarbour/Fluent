import 'package:fluent/data/models/word_quiz_model.dart';

abstract class WordQuizState {
  const WordQuizState();
}

class WordQuizInitial extends WordQuizState {
  const WordQuizInitial();
}

class WordQuizLoading extends WordQuizState {
  const WordQuizLoading();
}

/// Quiz loaded — user is answering questions.
class WordQuizInProgress extends WordQuizState {
  final List<WordQuizQuestion> questions;
  final int currentIndex;
  final int correctCount;
  final int wrongCount;

  /// Selected option id for current question (before confirm / after check)
  final int? selectedOptionId;

  /// Result of last check for current question (null = not checked yet)
  final WordQuizCheckResult? lastResult;

  /// True while waiting for checkAnswer API
  final bool isChecking;

  const WordQuizInProgress({
    required this.questions,
    required this.currentIndex,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.selectedOptionId,
    this.lastResult,
    this.isChecking = false,
  });

  WordQuizQuestion get current => questions[currentIndex];
  int get total => questions.length;
  bool get isLast => currentIndex >= total - 1;
  bool get hasAnswered => lastResult != null;

  WordQuizInProgress copyWith({
    List<WordQuizQuestion>? questions,
    int? currentIndex,
    int? correctCount,
    int? wrongCount,
    int? selectedOptionId,
    WordQuizCheckResult? lastResult,
    bool? isChecking,
    bool clearSelection = false,
    bool clearResult = false,
  }) {
    return WordQuizInProgress(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      selectedOptionId: clearSelection
          ? null
          : (selectedOptionId ?? this.selectedOptionId),
      lastResult: clearResult ? null : (lastResult ?? this.lastResult),
      isChecking: isChecking ?? this.isChecking,
    );
  }
}

class WordQuizFinished extends WordQuizState {
  final int total;
  final int correctCount;
  final int wrongCount;

  const WordQuizFinished({
    required this.total,
    required this.correctCount,
    required this.wrongCount,
  });

  double get accuracy => total == 0 ? 0 : correctCount / total;
}

class WordQuizFailure extends WordQuizState {
  final String message;
  const WordQuizFailure(this.message);
}

class WordQuizEmpty extends WordQuizState {
  final String message;
  const WordQuizEmpty([
    this.message = 'No words in your bank yet. Add words from lessons first.',
  ]);
}
