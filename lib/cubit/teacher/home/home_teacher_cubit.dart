import 'package:fluent/cubit/teacher/home/home_teacher_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/data/repository/lesson_repository.dart';
import 'package:fluent/data/repository/question_repository.dart';

class TeacherHomeCubit extends Cubit<TeacherHomeState> {
  final LessonRepository lessonRepository;
  final QuestionRepository questionRepository;

  TeacherHomeCubit(this.lessonRepository, this.questionRepository)
    : super(TeacherHomeInitial());

  Future<void> loadDashboardData() async {
    emit(TeacherHomeLoading());
    try {
      int totalCourses = 0;
      int totalLessons = 0;
      int totalQuestions = 0;

      // 1. جلب الكورسات
      final coursesRes = await lessonRepository.getTeacherCourses();
      if (coursesRes['success'] == true) {
        final coursesList = coursesRes['data'] as List;
        totalCourses = coursesList.length;

        // 2. جلب إجمالي الدروس
        for (var course in coursesList) {
          final lessonsRes = await lessonRepository.getLessonsByCourse(
            course.id,
            page: 1,
          );
          if (lessonsRes['success'] == true) {
            final data = lessonsRes['data'];

            // ✅ الحل الجذري: تحويل أي نوع رقمي (num) إلى int بشكل آمن وقاطع
            final total = data.total;
            if (total != null) {
              totalLessons += (total as num).toInt();
            } else if (data.lessons != null) {
              totalLessons += (data.lessons.length as num).toInt();
            }
          }
        }
      }

      // 3. جلب إجمالي الأسئلة
      final qRes = await questionRepository.getQuestions(page: 1);
      if (qRes['success'] == true) {
        final data = qRes['data'];

        // ✅ نفس الحل الجذري للأسئلة
        final total = data.total;
        if (total != null) {
          totalQuestions = (total as num).toInt();
        } else if (data.questions != null) {
          totalQuestions = (data.questions.length as num).toInt();
        }
      }

      emit(
        TeacherHomeLoaded(
          totalCourses: totalCourses,
          totalLessons: totalLessons,
          totalQuestions: totalQuestions,
        ),
      );
    } catch (e) {
      emit(TeacherHomeFailure(e.toString()));
    }
  }
}
