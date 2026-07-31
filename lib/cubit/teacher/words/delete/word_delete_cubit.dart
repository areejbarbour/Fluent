import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/data/repository/word_repository.dart';
import 'word_delete_state.dart';

class WordDeleteCubit extends Cubit<WordDeleteState> {
  final WordRepository wordRepository;
  WordDeleteCubit(this.wordRepository) : super(WordDeleteInitial());

  Future<void> deleteWord(int wordId) async {
    emit(WordDeleteLoading());
    try {
      final result = await wordRepository.deleteWord(wordId);
      if (result['success'] == true) {
        emit(WordDeleteSuccess(
          wordId,
          message: result['message'] ?? 'Word deleted successfully',
        ));
      } else {
        emit(WordDeleteFailure(
          result['message'] ?? 'Failed to delete word',
          errors: result['errors'] as Map<String, dynamic>?,
        ));
      }
    } catch (e) {
      emit(WordDeleteFailure(e.toString()));
    }
  }

  void reset() => emit(WordDeleteInitial());
}
