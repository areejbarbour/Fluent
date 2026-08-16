import 'package:fluent/cubit/teacher/home/home_teacher_state.dart';
import 'package:fluent/data/models/test_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/cubit/safe_cubit.dart';
import 'package:fluent/data/repository/lesson_repository.dart';
import 'package:fluent/data/repository/question_repository.dart';
import 'package:fluent/data/repository/test_repository.dart';

class TeacherHomeCubit extends SafeCubit<TeacherHomeState> {
  final LessonRepository lessonRepository;
  final QuestionRepository questionRepository;
  final TestRepository testRepository;

  TeacherHomeCubit(
    this.lessonRepository,
    this.questionRepository,
    this.testRepository,
  ) : super(TeacherHomeInitial());

  Future<void> loadDashboardData() async {
    emit(TeacherHomeLoading());
    try {
      int totalCourses = 0;
      int totalLessons = 0;
      int totalQuestions = 0;

      final coursesRes = await lessonRepository.getTeacherCourses();
      if (coursesRes['success'] == true) {
        final coursesList = coursesRes['data'] as List;
        totalCourses = coursesList.length;

        for (var course in coursesList) {
          final lessonsRes = await lessonRepository.getLessonsByCourse(
            course.id,
            page: 1,
          );
          if (lessonsRes['success'] == true) {
            final data = lessonsRes['data'];

            final total = data.total;
            if (total != null) {
              totalLessons += (total as num).toInt();
            } else if (data.lessons != null) {
              totalLessons += (data.lessons.length as num).toInt();
            }
          }
        }
      }

      final qRes = await questionRepository.getQuestions(page: 1);
      if (qRes['success'] == true) {
        final data = qRes['data'];

        final total = data.total;
        if (total != null) {
          totalQuestions = (total as num).toInt();
        } else if (data.questions != null) {
          totalQuestions = (data.questions.length as num).toInt();
        }
      }

      int totalTests = 0;
      int publishedTests = 0;
      int draftTests = 0;
      int pendingTests = 0;
      int inReviewTests = 0;
      int approvedTests = 0;
      int archivedTests = 0;
      int closedTests = 0;
      int changesRequestedTests = 0;
      List<TestModel> allTests = const [];

      final tRes = await testRepository.getTeacherTests();
      if (tRes['success'] == true) {
        allTests = (tRes['data'] as List<TestModel>? ?? const []);
        totalTests = allTests.length;

        for (final t in allTests) {
          switch (t.normalizedStatus) {
            case 'published':
              publishedTests++;
              break;
            case 'draft':
              draftTests++;
              break;
            case 'pending':
              pendingTests++;
              break;
            case 'in_review':
              inReviewTests++;
              break;
            case 'approved':
              approvedTests++;
              break;
            case 'archived':
              archivedTests++;
              break;
            case 'closed':
              closedTests++;
              break;
            case 'changes_requested':
              changesRequestedTests++;
              break;
          }
        }
      }

      final sorted = [...allTests];
      sorted.sort((a, b) {
        final ad = a.updatedAt ?? a.createdAt ?? '';
        final bd = b.updatedAt ?? b.createdAt ?? '';
        return bd.compareTo(ad);
      });
      final recent = sorted.take(3).toList();

      emit(
        TeacherHomeLoaded(
          totalCourses: totalCourses,
          totalLessons: totalLessons,
          totalQuestions: totalQuestions,
          totalTests: totalTests,
          publishedTests: publishedTests,
          draftTests: draftTests,
          pendingTests: pendingTests,
          inReviewTests: inReviewTests,
          approvedTests: approvedTests,
          archivedTests: archivedTests,
          closedTests: closedTests,
          changesRequestedTests: changesRequestedTests,
          recentTests: recent,
        ),
      );
    } catch (e) {
      emit(TeacherHomeFailure(e.toString()));
    }
  }
}
