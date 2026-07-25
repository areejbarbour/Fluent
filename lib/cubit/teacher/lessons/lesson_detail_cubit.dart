import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/data/models/lesson_model.dart';
import 'package:fluent/data/models/test_model.dart';
import 'package:fluent/data/repository/lesson_repository.dart';
import 'package:fluent/data/repository/test_repository.dart';
import 'lesson_detail_state.dart';

class LessonDetailCubit extends Cubit<LessonDetailState> {
  final LessonRepository lessonRepository;
  final TestRepository testRepository;

  LessonDetailCubit({
    required this.lessonRepository,
    required this.testRepository,
  }) : super(LessonDetailInitial());

  // ✅ جلب تفاصيل الدرس مع الاختبارات
  Future<void> loadLessonDetails(int lessonId) async {
    emit(LessonDetailLoading());

    try {
      // جلب تفاصيل الدرس
      final lessonResult = await lessonRepository.getLessonDetails(lessonId);

      if (!lessonResult['success']) {
        emit(LessonDetailError(
          message: lessonResult['message'] ?? 'Failed to load lesson',
        ));
        return;
      }

      final lesson = lessonResult['lesson'];

      // جلب جميع الاختبارات للدرس
      final testsResult = await testRepository.getAllTests();

      if (!testsResult['success']) {
        // إذا فشل جلب الاختبارات، نعرض الدرس بدون اختبارات
        emit(LessonDetailLoaded(
          lesson: lesson,
          tests: [],
          comments: lessonResult['comments'] ?? [],
        ));
        return;
      }

      // تفليتر الاختبارات للدرس الحالي فقط
      final allTests = testsResult['data'] as List<TestModel>;
      final lessonTests = testRepository.testsForLesson(
        allTests,
        lessonId,
      );

      emit(LessonDetailLoaded(
        lesson: lesson,
        tests: lessonTests,
        comments: lessonResult['comments'] ?? [],
      ));
    } catch (e) {
      emit(LessonDetailError(message: e.toString()));
    }
  }

  // ✅ حذف اختبار
  Future<void> deleteTest(int testId) async {
    emit(DeletingTest());

    try {
      final result = await testRepository.deleteTest(testId);

      if (result['success']) {
        // أعادة تحميل التفاصيل بعد الحذف
        final currentState = state;
        if (currentState is LessonDetailLoaded) {
          await loadLessonDetails(currentState.lesson['id']);
        }
        emit(TestDeletedSuccess(message: result['message'] ?? 'Test deleted'));
      } else {
        emit(LessonDetailError(
          message: result['message'] ?? 'Failed to delete test',
        ));
      }
    } catch (e) {
      emit(LessonDetailError(message: e.toString()));
    }
  }

  // ✅ تحديث حالة بعد إنشاء/تعديل اختبار
  Future<void> refreshTests(int lessonId) async {
    await loadLessonDetails(lessonId);
  }
}