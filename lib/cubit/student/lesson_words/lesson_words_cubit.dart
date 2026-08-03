import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/data/models/lesson_word_model.dart';
import 'package:fluent/data/repository/lesson_word_repository.dart';
import 'lesson_words_state.dart';

class LessonWordsCubit extends Cubit<LessonWordsState> {
  final LessonWordRepository repository;
  List<LessonWordModel> _currentWords = [];

  LessonWordsCubit(this.repository) : super(LessonWordsInitial());

  Future<void> fetchLessonWords(int lessonId) async {
    emit(LessonWordsLoading());
    print("🟡 [LessonWordsCubit] Fetching words for lesson #$lessonId...");

    final result = await repository.getLessonWords(lessonId);

    if (result['success'] == true) {
      _currentWords = List<LessonWordModel>.from(result['data'] ?? []);
      print("🎉 [LessonWordsCubit] Loaded ${_currentWords.length} words");
      emit(LessonWordsSuccess(_currentWords));
    } else {
      print("❌ [LessonWordsCubit] Failed: ${result['message']}");
      emit(LessonWordsFailure(
        result['message'] ?? 'فشل تحميل كلمات الدرس',
      ));
    }
  }

  Future<void> moveToLearning(int wordId) async {
  emit(LessonWordsSuccess(_currentWords, busyWordId: wordId));
  print("🟡 [LessonWordsCubit] Moving word #$wordId to learning...");

  final result = await repository.moveToLearning(wordId);

  if (result['success'] == true) {
    _currentWords = _currentWords.where((w) => w.id != wordId).toList();
    print("🎉 [LessonWordsCubit] Moved to learning & removed from list");
    emit(LessonWordsActionSuccess(
      message: result['message'] ?? 'تم النقل إلى التعلم',
      words: _currentWords,
    ));
    emit(LessonWordsSuccess(_currentWords));
  } else {
    print("❌ [LessonWordsCubit] Failed: ${result['message']}");
    emit(LessonWordsFailure(result['message'] ?? 'فشل النقل'));
    emit(LessonWordsSuccess(_currentWords));
  }
}

Future<void> moveToKnow(int wordId) async {
  emit(LessonWordsSuccess(_currentWords, busyWordId: wordId));
  print("🟡 [LessonWordsCubit] Moving word #$wordId to know...");

  final result = await repository.moveToKnow(wordId);

  if (result['success'] == true) {
    _currentWords = _currentWords.where((w) => w.id != wordId).toList();
    print("🎉 [LessonWordsCubit] Moved to know & removed from list");
    emit(LessonWordsActionSuccess(
      message: result['message'] ?? 'تم النقل إلى المعروف',
      words: _currentWords,
    ));
    emit(LessonWordsSuccess(_currentWords));
  } else {
    print("❌ [LessonWordsCubit] Failed: ${result['message']}");
    emit(LessonWordsFailure(result['message'] ?? 'فشل النقل'));
    emit(LessonWordsSuccess(_currentWords));
  }
}
}