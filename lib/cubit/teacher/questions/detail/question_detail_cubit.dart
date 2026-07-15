import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/data/repository/question_repository.dart';
import 'question_detail_state.dart';

class QuestionDetailCubit extends Cubit<QuestionDetailState> {
  final QuestionRepository questionRepository;

  QuestionDetailCubit(this.questionRepository)
      : super(QuestionDetailInitial());

  Future<void> loadQuestion(int id) async {
    emit(QuestionDetailLoading());
    print("🟡 [QuestionDetailCubit] loadQuestion id=$id");

    try {
      final result = await questionRepository.getQuestion(id);
      final success = result['success'] as bool? ?? false;
      if (success) {
        emit(QuestionDetailLoaded(result['data']));
      } else {
        emit(QuestionDetailFailure(
          result['message']?.toString() ?? 'Failed to load question',
          errors: result['errors'] as Map<String, dynamic>?,
        ));
      }
    } catch (e) {
      emit(QuestionDetailFailure(e.toString()));
    }
  }

  void reset() => emit(QuestionDetailInitial());
}