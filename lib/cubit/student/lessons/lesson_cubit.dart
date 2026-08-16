import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/cubit/safe_cubit.dart';
import '../../../data/repository/student_lesson_repository.dart';
import 'package:fluent/cubit/student/lessons/lesson_state.dart';

class StudentLessonsCubit extends SafeCubit<StudentLessonsState> {
  final StudentLessonRepository studentLessonRepository;
  StudentLessonsCubit(this.studentLessonRepository)
    : super(StudentLessonsInitial());

  Future<void> fetchStudentLessons(int courseId) async {
    emit(StudentLessonsLoading());
    print(" [StudentLessonsCubit] Fetching lessons for course $courseId...");

    final result = await studentLessonRepository.getStudentLessons(courseId);

    // The screen that owns this cubit may have been popped/disposed while
    // the request was in flight (e.g. user navigated back quickly). Emitting
    // on a closed cubit throws "Bad state: Cannot emit new states after
    // calling close", so bail out instead of crashing.
    if (isClosed) return;

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
