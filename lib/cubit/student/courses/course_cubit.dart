import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repository/course_repository.dart';
import 'package:fluent/cubit/student/courses/course_state.dart';

class StudentCoursesCubit extends Cubit<StudentCoursesState> {
  final CourseRepository courseRepository;
  StudentCoursesCubit(this.courseRepository) : super(StudentCoursesInitial());

  Future<void> fetchStudentCourses(int levelId) async {
    emit(StudentCoursesLoading());
    print("🟡 [StudentCoursesCubit] Fetching courses for level $levelId...");

    final result = await courseRepository.getStudentCourses(levelId);

    if (result['success'] == true) {
      print("🎉 [StudentCoursesCubit] Courses loaded successfully");
      emit(StudentCoursesSuccess(result['data']));
    } else {
      print("❌ [StudentCoursesCubit] Failed: ${result['message']}");
      emit(StudentCoursesFailure(result['message'] ?? 'فشل تحميل الكورسات'));
    }
  }
}