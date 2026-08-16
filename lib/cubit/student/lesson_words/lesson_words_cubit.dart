import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/cubit/safe_cubit.dart';
import 'package:fluent/data/models/lesson_word_model.dart';
import 'package:fluent/data/repository/lesson_word_repository.dart';
import 'lesson_words_state.dart';

class LessonWordsCubit extends SafeCubit<LessonWordsState> {
  final LessonWordRepository repository;
  List<LessonWordModel> _currentWords = [];

  LessonWordsCubit(this.repository) : super(LessonWordsInitial());

  Future<void> fetchLessonWords(int lessonId) async {
    emit(LessonWordsLoading());
    print(" [LessonWordsCubit] Fetching words for lesson #$lessonId...");

    final result = await repository.getLessonWords(lessonId);

    if (result['success'] == true) {
      _currentWords = List<LessonWordModel>.from(result['data'] ?? []);
      print(" [LessonWordsCubit] Loaded ${_currentWords.length} words");
      emit(LessonWordsSuccess(_currentWords));
    } else {
      print(" [LessonWordsCubit] Failed: ${result['message']}");
      emit(
        LessonWordsFailure(result['message'] ?? 'Failed to load lesson words'),
      );
    }
  }

  Future<void> moveToLearning(int wordId) async {
    emit(LessonWordsSuccess(_currentWords, busyWordId: wordId));
    print(" [LessonWordsCubit] Adding word #$wordId to learning...");

    final result = await repository.moveToLearning(wordId);

    if (result['success'] == true) {
      print(" [LessonWordsCubit] Added to learning (list unchanged)");
      emit(
        LessonWordsActionSuccess(
          message: result['message'] ?? 'Added to learning list',
          words: _currentWords,
        ),
      );
      emit(LessonWordsSuccess(_currentWords));
    } else {
      print(" [LessonWordsCubit] Failed: ${result['message']}");
      emit(
        LessonWordsFailure(result['message'] ?? 'Failed to update word status'),
      );
      emit(LessonWordsSuccess(_currentWords));
    }
  }

  Future<void> moveToKnow(int wordId) async {
    emit(LessonWordsSuccess(_currentWords, busyWordId: wordId));
    print(" [LessonWordsCubit] Adding word #$wordId to know...");

    final result = await repository.moveToKnow(wordId);

    if (result['success'] == true) {
      print(" [LessonWordsCubit] Added to know (list unchanged)");
      emit(
        LessonWordsActionSuccess(
          message: result['message'] ?? 'Added to known words',
          words: _currentWords,
        ),
      );
      emit(LessonWordsSuccess(_currentWords));
    } else {
      print(" [LessonWordsCubit] Failed: ${result['message']}");
      emit(
        LessonWordsFailure(result['message'] ?? 'Failed to update word status'),
      );
      emit(LessonWordsSuccess(_currentWords));
    }
  }
}
