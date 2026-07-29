import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluent/data/models/lesson_detail_model.dart';
import 'package:fluent/data/models/test_model.dart';
import 'package:fluent/data/repository/lesson_detail_repository.dart';
import 'package:fluent/data/repository/lesson_repository.dart';
import 'package:fluent/data/repository/test_repository.dart';
import 'lesson_detail_state.dart';

class LessonDetailCubit extends Cubit<LessonDetailState> {
  final LessonRepository lessonRepository;
  final TestRepository testRepository;
  final LessonDetailRepository lessonDetailRepository;

  /// مطابق لـ validation الباك: max:1000
  static const int maxCommentLength = 1000;

  int? _currentUserId;
  int _lessonId = 0;

  LessonDetailCubit({
    required this.lessonRepository,
    required this.testRepository,
    required this.lessonDetailRepository,
  }) : super(LessonDetailInitial());

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

  // ✅ جلب تفاصيل الدرس مع الاختبارات + كل صفحات التعليقات
  Future<void> loadLessonDetails(int lessonId) async {
    _lessonId = lessonId;
    emit(LessonDetailLoading());

    try {
      final userId = await _resolveCurrentUserId();

      // 1) تفاصيل الدرس + الصفحة الأولى للتعليقات (مسار المعلّم)
      final detailResult = await lessonDetailRepository.getLessonDetail(
        lessonId,
        page: 1,
        currentUserId: userId,
        teacher: true,
      );

      if (detailResult['success'] != true) {
        // fallback على lessonRepository القديم إن فشل
        final lessonResult = await lessonRepository.getLessonDetails(lessonId);
        if (!lessonResult['success']) {
          emit(
            LessonDetailError(
              message: lessonResult['message'] ?? 'Failed to load lesson',
            ),
          );
          return;
        }
        final commentsRaw = lessonResult['comments'];
        final parsed = LessonDetailModel.parseComments(
          commentsRaw,
          currentUserId: userId,
          requestedPage: 1,
        );
        final tests = await _loadLessonTests(lessonId);
        emit(
          LessonDetailLoaded(
            lesson: lessonResult['lesson'],
            tests: tests,
            comments: parsed.comments,
            commentsCurrentPage: parsed.currentPage,
            commentsLastPage: parsed.lastPage,
            commentsTotal: parsed.total,
          ),
        );
        return;
      }

      final pageData = detailResult['data'] as LessonDetailModel;
      final lessonMap = detailResult['rawLesson'] ?? pageData.lesson;

      // 2) تحميل باقي صفحات التعليقات
      final allComments = await _loadAllCommentPages(
        lessonId,
        pageData,
        userId,
      );

      // 3) الاختبارات
      final tests = await _loadLessonTests(lessonId);

      emit(
        LessonDetailLoaded(
          lesson: lessonMap,
          tests: tests,
          comments: allComments.comments,
          commentsCurrentPage: allComments.commentsCurrentPage,
          commentsLastPage: allComments.commentsLastPage,
          commentsTotal: allComments.commentsTotal,
        ),
      );
    } catch (e) {
      emit(LessonDetailError(message: e.toString()));
    }
  }

  Future<List<TestModel>> _loadLessonTests(int lessonId) async {
    final testsResult = await testRepository.getAllTests();
    if (testsResult['success'] != true) return [];
    final allTests = testsResult['data'] as List<TestModel>;
    return testRepository.testsForLesson(allTests, lessonId);
  }

  Future<LessonDetailModel> _loadAllCommentPages(
    int lessonId,
    LessonDetailModel firstPage,
    int? userId,
  ) async {
    var merged = List<LessonCommentModel>.from(firstPage.comments);
    var currentPage = firstPage.commentsCurrentPage;
    var lastPage = firstPage.commentsLastPage;
    const maxPages = 50;

    var pageLen = firstPage.comments.length;
    var shouldContinue =
        firstPage.hasMoreComments ||
        pageLen >= LessonDetailModel.backendCommentsPageSize;

    while (shouldContinue && currentPage < maxPages) {
      final next = currentPage + 1;
      print(
        "📄 [TeacherLessonDetail] Loading comments page $next "
        "(have ${merged.length} so far)",
      );
      final result = await lessonDetailRepository.getLessonDetail(
        lessonId,
        page: next,
        currentUserId: userId,
        teacher: true,
      );
      if (result['success'] != true) break;

      final pageData = result['data'] as LessonDetailModel;
      final existingIds = merged.map((c) => c.id).toSet();
      var added = 0;
      for (final c in pageData.comments) {
        if (!existingIds.contains(c.id)) {
          merged.add(c);
          existingIds.add(c.id);
          added++;
        }
      }

      currentPage = pageData.commentsCurrentPage;
      lastPage = pageData.commentsLastPage;
      pageLen = pageData.comments.length;

      if (pageLen == 0 || added == 0) {
        lastPage = currentPage;
        break;
      }
      if (pageLen < LessonDetailModel.backendCommentsPageSize) {
        lastPage = currentPage;
        break;
      }
      if (pageData.hasMoreComments ||
          pageLen >= LessonDetailModel.backendCommentsPageSize) {
        lastPage = currentPage + 1;
        shouldContinue = true;
      } else {
        lastPage = currentPage;
        shouldContinue = false;
      }
    }

    return firstPage.copyWith(
      comments: merged,
      commentsCurrentPage: currentPage,
      commentsLastPage: lastPage,
      commentsTotal: merged.length,
    );
  }

  Future<void> loadMoreComments() async {
    final current = state;
    if (current is! LessonDetailLoaded) return;
    if (current.isLoadingMoreComments || !current.hasMoreComments) return;
    if (_lessonId <= 0) return;

    emit(current.copyWith(isLoadingMoreComments: true));
    final userId = await _resolveCurrentUserId();
    final nextPage = current.commentsCurrentPage + 1;

    final result = await lessonDetailRepository.getLessonDetail(
      _lessonId,
      page: nextPage,
      currentUserId: userId,
      teacher: true,
    );

    if (result['success'] == true) {
      final pageData = result['data'] as LessonDetailModel;
      final existingIds = current.comments.map((c) => c.id).toSet();
      final newItems = pageData.comments
          .where((c) => !existingIds.contains(c.id))
          .toList();
      final appended = [...current.comments, ...newItems];

      int lastPage = pageData.commentsLastPage;
      if (newItems.isEmpty ||
          pageData.comments.length <
              LessonDetailModel.backendCommentsPageSize) {
        lastPage = pageData.commentsCurrentPage;
      } else if (pageData.comments.length >=
          LessonDetailModel.backendCommentsPageSize) {
        lastPage = pageData.commentsCurrentPage + 1;
      }

      emit(
        current.copyWith(
          comments: appended,
          commentsCurrentPage: pageData.commentsCurrentPage,
          commentsLastPage: lastPage,
          commentsTotal: appended.length,
          isLoadingMoreComments: false,
        ),
      );
    } else {
      emit(current.copyWith(isLoadingMoreComments: false));
    }
  }

  Future<String?> submitComment(int lessonId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.length > maxCommentLength) {
      return 'Comment must not exceed $maxCommentLength characters';
    }

    final current = state;
    if (current is LessonDetailLoaded && !current.canCreateComment) {
      return 'You cannot create a comment for this lesson.';
    }

    if (current is LessonDetailLoaded) {
      emit(current.copyWith(isBusyComment: true));
    }

    final userId = await _resolveCurrentUserId();
    final result = await lessonDetailRepository.postComment(
      lessonId,
      trimmed,
      currentUserId: userId,
    );

    if (result['success'] == true) {
      final newComment = (result['data'] as LessonCommentModel).copyWith(
        isOwn: true,
      );
      final s = state;
      if (s is LessonDetailLoaded) {
        emit(
          s.copyWith(
            comments: [newComment, ...s.comments],
            commentsTotal: s.commentsTotal + 1,
            isBusyComment: false,
          ),
        );
      }
      return null;
    }

    final s = state;
    if (s is LessonDetailLoaded) {
      emit(s.copyWith(isBusyComment: false));
    }
    return result['message'] ?? 'فشل في إضافة التعليق';
  }

  Future<String?> editComment(int commentId, String newText) async {
    final trimmed = newText.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.length > maxCommentLength) {
      return 'Comment must not exceed $maxCommentLength characters';
    }

    final current = state;
    if (current is! LessonDetailLoaded) return null;

    if (!current.canUpdateComments) {
      return 'Comments cannot be updated for this lesson.';
    }

    final target = current.comments.where((c) => c.id == commentId);
    if (target.isEmpty || !target.first.isOwn) {
      return 'You can only edit your own comments.';
    }

    emit(current.copyWith(isBusyComment: true));
    final userId = await _resolveCurrentUserId();
    final result = await lessonDetailRepository.updateComment(
      commentId,
      trimmed,
      currentUserId: userId,
    );

    if (result['success'] == true) {
      final prev = target.first;
      final raw = result['data'] as LessonCommentModel;
      final updatedComment = raw.copyWith(
        isOwn: true,
        user: raw.user ?? prev.user,
      );
      final updated = current.comments
          .map((c) => c.id == commentId ? updatedComment : c)
          .toList();
      emit(current.copyWith(comments: updated, isBusyComment: false));
      return null;
    }

    emit(current.copyWith(isBusyComment: false));
    return result['message'] ?? 'فشل في تعديل التعليق';
  }

  Future<String?> removeComment(int commentId) async {
    final current = state;
    if (current is! LessonDetailLoaded) return null;

    final target = current.comments.where((c) => c.id == commentId);
    // الطالب: own فقط | المعلّم: own أو صلاحية archive lesson من الباك
    // في UI نسمح بـ own؛ الباك يرفض غير المصرّح
    if (target.isEmpty || !target.first.isOwn) {
      return 'You can only delete your own comments.';
    }

    emit(current.copyWith(isBusyComment: true));
    final result = await lessonDetailRepository.deleteComment(commentId);

    if (result['success'] == true) {
      final updated = current.comments.where((c) => c.id != commentId).toList();
      emit(
        current.copyWith(
          comments: updated,
          commentsTotal: (current.commentsTotal - 1).clamp(
            0,
            current.commentsTotal,
          ),
          isBusyComment: false,
        ),
      );
      return null;
    }

    emit(current.copyWith(isBusyComment: false));
    return result['message'] ?? 'فشل في حذف التعليق';
  }

  // ✅ حذف اختبار
  Future<void> deleteTest(int testId) async {
    emit(DeletingTest());

    try {
      final result = await testRepository.deleteTest(testId);

      if (result['success']) {
        final currentState = state;
        if (currentState is LessonDetailLoaded) {
          final id = currentState.lesson is Map
              ? currentState.lesson['id']
              : _lessonId;
          await loadLessonDetails(id is int ? id : _lessonId);
        }
        emit(TestDeletedSuccess(message: result['message'] ?? 'Test deleted'));
      } else {
        emit(
          LessonDetailError(
            message: result['message'] ?? 'Failed to delete test',
          ),
        );
      }
    } catch (e) {
      emit(LessonDetailError(message: e.toString()));
    }
  }

  Future<void> refreshTests(int lessonId) async {
    await loadLessonDetails(lessonId);
  }
}
