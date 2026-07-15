
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/data/repository/question_repository.dart';
import 'question_delete_state.dart';

class QuestionDeleteCubit extends Cubit<QuestionDeleteState> {
  final QuestionRepository questionRepository;

  QuestionDeleteCubit(this.questionRepository) : super(QuestionDeleteInitial());

  Future<void> deleteQuestion(int id) async {
    emit(QuestionDeleteLoading());
    print("🟡 [QuestionDeleteCubit] deleteQuestion id=$id");

    try {
      final result = await questionRepository.deleteQuestion(id);
      final success = result['success'] as bool? ?? false;
      if (success) {
        emit(QuestionDeleteSuccess(
          result['message']?.toString() ?? 'Question deleted',
        ));
      } else {
        emit(QuestionDeleteFailure(
          result['message']?.toString() ?? 'Failed to delete question',
          errors: result['errors'] as Map<String, dynamic>?,
        ));
      }
    } catch (e) {
      emit(QuestionDeleteFailure(e.toString()));
    }
  }

  void reset() => emit(QuestionDeleteInitial());
}