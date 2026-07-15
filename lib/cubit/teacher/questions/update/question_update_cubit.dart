
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/data/repository/question_repository.dart';
import 'question_update_state.dart';

class QuestionUpdateCubit extends Cubit<QuestionUpdateState> {
  final QuestionRepository questionRepository;

  QuestionUpdateCubit(this.questionRepository) : super(QuestionUpdateInitial());

  Future<void> updateQuestion(int id, FormData formData) async {
    emit(QuestionUpdateLoading());
    print("🟡 [QuestionUpdateCubit] updateQuestion id=$id");

    try {
      final result = await questionRepository.updateQuestion(id, formData);
      final success = result['success'] as bool? ?? false;
      if (success) {
        emit(QuestionUpdateSuccess(
          status: result['status']?.toString() ?? 'updated',
          message: result['message']?.toString() ?? 'Question updated',
          question: result['data'],
        ));
      } else {
        emit(QuestionUpdateFailure(
          result['message']?.toString() ?? 'Failed to update question',
          errors: result['errors'] as Map<String, dynamic>?,
        ));
      }
    } catch (e) {
      emit(QuestionUpdateFailure(e.toString()));
    }
  }

  void reset() => emit(QuestionUpdateInitial());
} 