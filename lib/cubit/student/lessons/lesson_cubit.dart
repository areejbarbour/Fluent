import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repository/student_lesson_repository.dart';
import 'package:fluent/cubit/student/lessons/lesson_state.dart';

class StudentLessonsCubit extends Cubit<StudentLessonsState> {
  final StudentLessonRepository studentLessonRepository;
  StudentLessonsCubit(this.studentLessonRepository)
    : super(StudentLessonsInitial());

  Future<void> fetchStudentLessons(int courseId) async {
    emit(StudentLessonsLoading());
    print(" [StudentLessonsCubit] Fetching lessons for course $courseId...");

    final result = await studentLessonRepository.getStudentLessons(courseId);

    if (result['success'] == true) {
      print(" [StudentLessonsCubit] Lessons loaded successfully");
      emit(StudentLessonsSuccess(result['data']));
    } else {
      print(" [StudentLessonsCubit] Failed: ${result['message']}");
      emit(
        StudentLessonsFailure(result['message'] ?? 'Failed to load lessons'),
      );
    }
  }
}
