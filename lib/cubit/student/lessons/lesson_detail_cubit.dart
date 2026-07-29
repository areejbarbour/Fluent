
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/lesson_detail_model.dart';
import '../../../data/repository/lesson_detail_repository.dart';
import 'package:fluent/cubit/student/lessons/lesson_detail_state.dart';

class LessonDetailCubit extends Cubit<LessonDetailState> {
  final LessonDetailRepository lessonDetailRepository;
  LessonDetailCubit(this.lessonDetailRepository)
      : super(LessonDetailInitial());

  Future<void> fetchLessonDetail(int lessonId) async {
    emit(LessonDetailLoading());
    print("🟡 [LessonDetailCubit] Fetching detail for lesson $lessonId...");

    final result = await lessonDetailRepository.getLessonDetail(lessonId);

    if (result['success'] == true) {
      print("🎉 [LessonDetailCubit] Lesson detail loaded successfully");
      emit(LessonDetailSuccess(result['data']));
    } else {
      print("❌ [LessonDetailCubit] Failed: ${result['message']}");
      emit(LessonDetailFailure(result['message'] ?? 'فشل تحميل تفاصيل الدرس'));
    }
  }

  void _insertComment(LessonCommentModel comment) {
    final current = state;
    if (current is! LessonDetailSuccess) return;

    final updatedData = LessonDetailModel(
      lesson: current.data.lesson,
      comments: [comment, ...current.data.comments],
    );
    emit(LessonDetailSuccess(updatedData));
  }

  Future<String?> submitComment(int lessonId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;

    print("🟡 [LessonDetailCubit] Submitting comment for lesson $lessonId...");
    final result = await lessonDetailRepository.postComment(lessonId, trimmed);

    if (result['success'] == true) {
      print("🎉 [LessonDetailCubit] Comment added successfully");
      final newComment =
          (result['data'] as LessonCommentModel).copyWith(isOwn: true);
      _insertComment(newComment);
      return null;
    } else {
      print("❌ [LessonDetailCubit] Comment failed: ${result['message']}");
      return result['message'] ?? 'فشل في إضافة التعليق';
    }
  }

  Future<String?> editComment(int commentId, String newText) async {
    final trimmed = newText.trim();
    if (trimmed.isEmpty) return null;

    final current = state;
    if (current is! LessonDetailSuccess) return null;

    print("🟡 [LessonDetailCubit] Updating comment $commentId...");
    final result =
        await lessonDetailRepository.updateComment(commentId, trimmed);

    if (result['success'] == true) {
      print("🎉 [LessonDetailCubit] Comment updated successfully");
      final updatedComment =
          (result['data'] as LessonCommentModel).copyWith(isOwn: true);

      final updatedComments = current.data.comments
          .map((c) => c.id == commentId ? updatedComment : c)
          .toList();

      emit(LessonDetailSuccess(
        LessonDetailModel(lesson: current.data.lesson, comments: updatedComments),
      ));
      return null;
    } else {
      print("❌ [LessonDetailCubit] Update failed: ${result['message']}");
      return result['message'] ?? 'فشل في تعديل التعليق';
    }
  }
  
  Future<String?> removeComment(int commentId) async {
    final current = state;
    if (current is! LessonDetailSuccess) return null;

    print("🟡 [LessonDetailCubit] Deleting comment $commentId...");
    final result = await lessonDetailRepository.deleteComment(commentId);

    if (result['success'] == true) {
      print("🎉 [LessonDetailCubit] Comment deleted successfully");
      final updatedComments =
          current.data.comments.where((c) => c.id != commentId).toList();

      emit(LessonDetailSuccess(
        LessonDetailModel(lesson: current.data.lesson, comments: updatedComments),
      ));
      return null;
    } else {
      print("❌ [LessonDetailCubit] Delete failed: ${result['message']}");
      return result['message'] ?? 'فشل في حذف التعليق';
    }
  }
}