
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/data/repository/question_repository.dart';
import 'question_blocking_tests_state.dart';

class QuestionBlockingTestsCubit extends Cubit<QuestionBlockingTestsState> {
  final QuestionRepository questionRepository;

  QuestionBlockingTestsCubit(this.questionRepository)
      : super(QuestionBlockingTestsInitial());

  Future<void> fetchBlockingTests(int id) async {
    emit(QuestionBlockingTestsLoading());
    print("🟡 [QuestionBlockingTestsCubit] fetchBlockingTests id=$id");

    try {
      final result = await questionRepository.blockingTests(id);
      final success = result['success'] as bool? ?? false;
      if (success) {
        emit(QuestionBlockingTestsLoaded(result['data']));
      } else {
        emit(QuestionBlockingTestsFailure(
          result['message']?.toString() ?? 'Failed to load blocking tests',
          errors: result['errors'] as Map<String, dynamic>?,
        ));
      }
    } catch (e) {
      emit(QuestionBlockingTestsFailure(e.toString()));
    }
  }

  void reset() => emit(QuestionBlockingTestsInitial());
}