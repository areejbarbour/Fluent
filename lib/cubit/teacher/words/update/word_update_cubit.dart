import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/data/repository/word_repository.dart';
import 'word_update_state.dart';

class WordUpdateCubit extends Cubit<WordUpdateState> {
  final WordRepository wordRepository;
  WordUpdateCubit(this.wordRepository) : super(WordUpdateInitial());

  Future<void> updateWord({
    required int wordId,
    required String wordEn,
    required String wordAr,
  }) async {
    emit(WordUpdateLoading());
    try {
      final result = await wordRepository.updateWord(
        wordId,
        wordEn: wordEn.trim(),
        wordAr: wordAr.trim(),
      );
      if (result['success'] == true) {
        emit(WordUpdateSuccess(result['data']));
      } else {
        emit(WordUpdateFailure(
          result['message'] ?? 'Failed to update word',
          errors: result['errors'] as Map<String, dynamic>?,
        ));
      }
    } catch (e) {
      emit(WordUpdateFailure(e.toString()));
    }
  }

  void reset() => emit(WordUpdateInitial());
}
