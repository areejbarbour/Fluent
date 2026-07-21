import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/data/repository/lesson_repository.dart';
import 'lesson_form_state.dart';

class LessonFormCubit extends Cubit<LessonFormState> {
  final LessonRepository lessonRepository;
  LessonFormCubit(this.lessonRepository) : super(LessonFormInitial());

  Future<void> createLesson(int courseId, FormData formData) async {
    emit(LessonFormLoading());
    try {
      final result = await lessonRepository.createLesson(courseId, formData);
      if (result['success'] == true) {
        emit(LessonFormSuccess(result['data']));
      } else {
        emit(
          LessonFormFailure(
            result['message'] ?? 'Failed to create lesson',
            errors: result['errors'],
          ),
        );
      }
    } catch (e) {
      print('❌ Error creating lesson: $e'); // ✅ للطباعة
      emit(LessonFormFailure(e.toString()));
    }
  }

  Future<void> updateLesson(int lessonId, FormData formData) async {
    emit(LessonFormLoading());
    try {
      final result = await lessonRepository.updateLesson(lessonId, formData);
      if (result['success'] == true) {
        emit(LessonFormSuccess(result['data']));
      } else {
        emit(
          LessonFormFailure(
            result['message'] ?? 'Failed to update lesson',
            errors: result['errors'],
          ),
        );
      }
    } catch (e) {
      emit(LessonFormFailure(e.toString()));
    }
  }

  void reset() => emit(LessonFormInitial());
}
