import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/data/repository/lesson_repository.dart';
import 'lesson_delete_state.dart';

class LessonDeleteCubit extends Cubit<LessonDeleteState> {
  final LessonRepository lessonRepository;
  LessonDeleteCubit(this.lessonRepository) : super(LessonDeleteInitial());

  Future<void> deleteLesson(int lessonId) async {
    emit(LessonDeleteLoading());
    try {
      final result = await lessonRepository.deleteLesson(lessonId);
      if (result['success'] == true) {
        emit(LessonDeleteSuccess(result['message']));
      } else {
        emit(LessonDeleteFailure(result['message'] ?? 'Failed to delete'));
      }
    } catch (e) {
      emit(LessonDeleteFailure(e.toString()));
    }
  }
}
