import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/data/repository/question_repository.dart';
import 'question_status_state.dart';

class QuestionStatusCubit extends Cubit<QuestionStatusState> {
  final QuestionRepository questionRepository;

  QuestionStatusCubit(this.questionRepository) : super(QuestionStatusInitial());

  Future<void> checkStatus(int id) async {
    emit(QuestionStatusLoading());
    print("🟡 [QuestionStatusCubit] checkStatus id=$id");

    try {
      final result = await questionRepository.checkStatus(id);
      final success = result['success'] as bool? ?? false;
      if (success) {
        emit(QuestionStatusLoaded(result['data']));
      } else {
        emit(QuestionStatusFailure(
          result['message']?.toString() ?? 'Failed to load status',
          errors: result['errors'] as Map<String, dynamic>?,
        ));
      }
    } catch (e) {
      emit(QuestionStatusFailure(e.toString()));
    }
  }

  void reset() => emit(QuestionStatusInitial());
} 