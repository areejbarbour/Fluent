import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/data/repository/word_repository.dart';
import 'word_create_state.dart';

class WordCreateCubit extends Cubit<WordCreateState> {
  final WordRepository wordRepository;
  WordCreateCubit(this.wordRepository) : super(WordCreateInitial());

  /// Backend StoreWordRequest requires audio file.
  Future<void> createWord({
    required int lessonId,
    required String wordEn,
    required String wordAr,
    required File audioFile,
    String? audioFileName,
  }) async {
    emit(WordCreateLoading());
    try {
      final result = await wordRepository.createWord(
        lessonId,
        wordEn: wordEn.trim(),
        wordAr: wordAr.trim(),
        audioFile: audioFile,
        audioFileName: audioFileName,
      );
      if (result['success'] == true) {
        emit(WordCreateSuccess(result['data']));
      } else {
        emit(
          WordCreateFailure(
            result['message'] ?? 'Failed to create word',
            errors: result['errors'] as Map<String, dynamic>?,
          ),
        );
      }
    } catch (e) {
      emit(WordCreateFailure(e.toString()));
    }
  }

  void reset() => emit(WordCreateInitial());
}
