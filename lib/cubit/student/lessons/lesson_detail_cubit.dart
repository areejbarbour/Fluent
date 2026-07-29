import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/lesson_detail_model.dart';
import '../../../data/repository/lesson_detail_repository.dart';
import 'package:fluent/cubit/student/lessons/lesson_detail_state.dart';

class LessonDetailCubit extends Cubit<LessonDetailState> {
  /// مطابق لـ validation الباك: max:1000
  static const int maxCommentLength = 1000;

  final LessonDetailRepository lessonDetailRepository;
  LessonDetailCubit(this.lessonDetailRepository) : super(LessonDetailInitial());

  int? _currentUserId;
  int _lessonId = 0;

  Future<int?> _resolveCurrentUserId() async {
    if (_currentUserId != null && _currentUserId! > 0) {
      return _currentUserId;
    }
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('user_id');
    if (id != null && id > 0) {
      _currentUserId = id;
      return id;
    }
    return null;
  }

  Future<void> fetchLessonDetail(int lessonId) async {
    _lessonId = lessonId;
    emit(LessonDetailLoading());
    print("🟡 [LessonDetailCubit] Fetching detail for lesson $lessonId...");

    final userId = await _resolveCurrentUserId();
    final result = await lessonDetailRepository.getLessonDetail(
      lessonId,
      page: 1,
      currentUserId: userId,
    );

    if (result['success'] == true) {
      print("🎉 [LessonDetailCubit] Lesson detail loaded successfully");
      var data = result['data'] as LessonDetailModel;

      // تحميل باقي صفحات التعليقات تلقائياً إن وُجد pagination
      data = await _loadAllCommentPages(lessonId, data, userId);

      emit(LessonDetailSuccess(data));
    } else {
      print("❌ [LessonDetailCubit] Failed: ${result['message']}");
      emit(LessonDetailFailure(result['message'] ?? 'فشل تحميل تفاصيل الدرس'));
    }
  }

  /// يجلب كل صفحات التعليقات حتى تكتمل القائمة (منطق الباك: paginate)
  Future<LessonDetailModel> _loadAllCommentPages(
    int lessonId,
    LessonDetailModel firstPage,
    int? userId,
  ) async {
    if (!firstPage.hasMoreComments) return firstPage;

    var merged = List<LessonCommentModel>.from(firstPage.comments);
    var currentPage = firstPage.commentsCurrentPage;
    var lastPage = firstPage.commentsLastPage;
    var total = firstPage.commentsTotal;

    while (currentPage < lastPage) {
      final next = currentPage + 1;
      print("📄 [LessonDetailCubit] Loading comments page $next / $lastPage");
      final result = await lessonDetailRepository.getLessonDetail(
        lessonId,
        page: next,
        currentUserId: userId,
      );
      if (result['success'] != true) break;

      final pageData = result['data'] as LessonDetailModel;
      final existingIds = merged.map((c) => c.id).toSet();
      for (final c in pageData.comments) {
        if (!existingIds.contains(c.id)) {
          merged.add(c);
          existingIds.add(c.id);
        }
      }
      currentPage = pageData.commentsCurrentPage;
      lastPage = pageData.commentsLastPage;
      total = pageData.commentsTotal;

      if (pageData.comments.isEmpty) break;
    }

    return firstPage.copyWith(
      comments: merged,
      commentsCurrentPage: currentPage,
      commentsLastPage: lastPage,
      commentsTotal: total > 0 ? total : merged.length,
    );
  }

  /// تحميل الصفحة التالية يدوياً (إن احتجت UI لـ load more)
  Future<void> loadMoreComments() async {
    final current = state;
    if (current is! LessonDetailSuccess) return;
    if (current.isLoadingMore || !current.data.hasMoreComments) return;
    if (_lessonId <= 0) return;

    emit(current.copyWith(isLoadingMore: true));
    final userId = await _resolveCurrentUserId();
    final nextPage = current.data.commentsCurrentPage + 1;

    final result = await lessonDetailRepository.getLessonDetail(
      _lessonId,
      page: nextPage,
      currentUserId: userId,
    );

    if (result['success'] == true) {
      final pageData = result['data'] as LessonDetailModel;
      final existingIds = current.data.comments.map((c) => c.id).toSet();
      final appended = [
        ...current.data.comments,
        ...pageData.comments.where((c) => !existingIds.contains(c.id)),
      ];
      emit(
        LessonDetailSuccess(
          current.data.copyWith(
            comments: appended,
            commentsCurrentPage: pageData.commentsCurrentPage,
            commentsLastPage: pageData.commentsLastPage,
            commentsTotal: pageData.commentsTotal,
          ),
          isLoadingMore: false,
        ),
      );
    } else {
      emit(current.copyWith(isLoadingMore: false));
    }
  }

  void _insertComment(LessonCommentModel comment) {
    final current = state;
    if (current is! LessonDetailSuccess) return;

    final updatedData = current.data.copyWith(
      comments: [comment, ...current.data.comments],
      commentsTotal: current.data.commentsTotal + 1,
    );
    emit(LessonDetailSuccess(updatedData));
  }

  Future<String?> submitComment(int lessonId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.length > maxCommentLength) {
      return 'Comment must not exceed $maxCommentLength characters';
    }

    // منطق الباك: لا تعليق إلا إذا الدرس published
    final current = state;
    if (current is LessonDetailSuccess && !current.data.canCreateComment) {
      return 'You cannot create a comment for this lesson.';
    }

    print("🟡 [LessonDetailCubit] Submitting comment for lesson $lessonId...");
    final userId = await _resolveCurrentUserId();
    final result = await lessonDetailRepository.postComment(
      lessonId,
      trimmed,
      currentUserId: userId,
    );

    if (result['success'] == true) {
      print("🎉 [LessonDetailCubit] Comment added successfully");
      final newComment = (result['data'] as LessonCommentModel).copyWith(
        isOwn: true,
      );
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
    if (trimmed.length > maxCommentLength) {
      return 'Comment must not exceed $maxCommentLength characters';
    }

    final current = state;
    if (current is! LessonDetailSuccess) return null;

    // منطق الباك: لا تعديل إذا archived / closed
    if (!current.data.canUpdateComments) {
      return 'Comments cannot be updated for this lesson.';
    }

    // منطق الباك: التعديل لصاحب التعليق فقط
    final target = current.data.comments.where((c) => c.id == commentId);
    if (target.isEmpty || !target.first.isOwn) {
      return 'You can only edit your own comments.';
    }

    print("🟡 [LessonDetailCubit] Updating comment $commentId...");
    final userId = await _resolveCurrentUserId();
    final result = await lessonDetailRepository.updateComment(
      commentId,
      trimmed,
      currentUserId: userId,
    );

    if (result['success'] == true) {
      print("🎉 [LessonDetailCubit] Comment updated successfully");
      // الباك عند التحديث قد لا يرجع user — نحتفظ ببيانات التعليق السابق
      final prev = target.first;
      final raw = result['data'] as LessonCommentModel;
      final updatedComment = raw.copyWith(
        isOwn: true,
        user: raw.user ?? prev.user,
      );

      final updatedComments = current.data.comments
          .map((c) => c.id == commentId ? updatedComment : c)
          .toList();

      emit(
        LessonDetailSuccess(current.data.copyWith(comments: updatedComments)),
      );
      return null;
    } else {
      print("❌ [LessonDetailCubit] Update failed: ${result['message']}");
      return result['message'] ?? 'فشل في تعديل التعليق';
    }
  }

  Future<String?> removeComment(int commentId) async {
    final current = state;
    if (current is! LessonDetailSuccess) return null;

    // منطق الباك: الحذف لصاحب التعليق (UI الطالب = own فقط)
    final target = current.data.comments.where((c) => c.id == commentId);
    if (target.isEmpty || !target.first.isOwn) {
      return 'You can only delete your own comments.';
    }

    print("🟡 [LessonDetailCubit] Deleting comment $commentId...");
    final result = await lessonDetailRepository.deleteComment(commentId);

    if (result['success'] == true) {
      print("🎉 [LessonDetailCubit] Comment deleted successfully");
      final updatedComments = current.data.comments
          .where((c) => c.id != commentId)
          .toList();

      emit(
        LessonDetailSuccess(
          current.data.copyWith(
            comments: updatedComments,
            commentsTotal: (current.data.commentsTotal - 1).clamp(
              0,
              current.data.commentsTotal,
            ),
          ),
        ),
      );
      return null;
    } else {
      print("❌ [LessonDetailCubit] Delete failed: ${result['message']}");
      return result['message'] ?? 'فشل في حذف التعليق';
    }
  }
}
