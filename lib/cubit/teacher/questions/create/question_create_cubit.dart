import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/data/repository/question_repository.dart';
import 'question_create_state.dart';

class QuestionCreateCubit extends Cubit<QuestionCreateState> {
  final QuestionRepository questionRepository;

  QuestionCreateCubit(this.questionRepository) : super(QuestionCreateInitial());

  Future<void> createQuestion(FormData formData) async {
    emit(QuestionCreateLoading());
    print("🟡 [QuestionCreateCubit] createQuestion");

    try {
      final result = await questionRepository.createQuestion(formData);
      final success = result['success'] as bool? ?? false;
      if (success) {
        emit(QuestionCreateSuccess(
          result['data'],
          'Question created successfully',
        ));
      } else {
        emit(QuestionCreateFailure(
          result['message']?.toString() ?? 'Failed to create question',
          errors: result['errors'] as Map<String, dynamic>?,
        ));
      }
    } catch (e) {
      emit(QuestionCreateFailure(e.toString()));
    }
  }

  void reset() => emit(QuestionCreateInitial());
}