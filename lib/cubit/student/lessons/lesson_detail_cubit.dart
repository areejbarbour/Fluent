import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repository/lesson_detail_repository.dart';
import 'package:fluent/cubit/student/lessons/lesson_detail_state.dart';

class LessonDetailCubit extends Cubit<LessonDetailState> {
  final LessonDetailRepository lessonDetailRepository;
  LessonDetailCubit(this.lessonDetailRepository) : super(LessonDetailInitial());

  Future<void> fetchLessonDetail(int lessonId) async {
    emit(LessonDetailLoading());
    print("🟡 [LessonDetailCubit] Fetching lesson detail for $lessonId...");

    final result = await lessonDetailRepository.getLessonDetail(lessonId);

    if (result['success'] == true) {
      print("🎉 [LessonDetailCubit] Lesson detail loaded successfully");
      emit(LessonDetailSuccess(result['data']));
    } else {
      print("❌ [LessonDetailCubit] Failed: ${result['message']}");
      emit(LessonDetailFailure(result['message'] ?? 'فشل تحميل تفاصيل الدرس'));
    }
  }
}