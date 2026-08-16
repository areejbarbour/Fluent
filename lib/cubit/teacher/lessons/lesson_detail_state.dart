import 'package:fluent/data/models/lesson_detail_model.dart';
import 'package:fluent/data/models/test_model.dart';
import 'package:fluent/data/models/word_model.dart';

abstract class LessonDetailState {}

class LessonDetailInitial extends LessonDetailState {}

class LessonDetailLoading extends LessonDetailState {}

class LessonDetailLoaded extends LessonDetailState {
  final dynamic lesson;
  final List<TestModel> tests;
  final List<WordModel> words;
  final List<LessonCommentModel> comments;
  final int commentsCurrentPage;
  final int commentsLastPage;
  final int commentsTotal;
  final bool isLoadingMoreComments;
  final bool isBusyComment;
  final bool isBusyWord;

  LessonDetailLoaded({
    required this.lesson,
    required this.tests,
    this.words = const [],
    required this.comments,
    this.commentsCurrentPage = 1,
    this.commentsLastPage = 1,
    this.commentsTotal = 0,
    this.isLoadingMoreComments = false,
    this.isBusyComment = false,
    this.isBusyWord = false,
  });

  bool get hasMoreComments => commentsCurrentPage < commentsLastPage;

  bool get canCreateComment {
    final status = _lessonStatus;
    return status == null || status == 'published';
  }

  bool get canUpdateComments {
    final status = _lessonStatus;
    if (status == null) return true;
    return status != 'archived' && status != 'closed';
  }

  
  bool get canManageWords {
    final status = _lessonStatus;
    if (status == null) return false;
    return const {'draft', 'pending', 'changes_requested'}.contains(status);
  }

  String? get _lessonStatus {
    if (lesson is Map) {
      final s = (lesson as Map)['status']?.toString().toLowerCase();
      return s;
    }
    return null;
  }

  LessonDetailLoaded copyWith({
    dynamic lesson,
    List<TestModel>? tests,
    List<WordModel>? words,
    List<LessonCommentModel>? comments,
    int? commentsCurrentPage,
    int? commentsLastPage,
    int? commentsTotal,
    bool? isLoadingMoreComments,
    bool? isBusyComment,
    bool? isBusyWord,
  }) {
    return LessonDetailLoaded(
      lesson: lesson ?? this.lesson,
      tests: tests ?? this.tests,
      words: words ?? this.words,
      comments: comments ?? this.comments,
      commentsCurrentPage: commentsCurrentPage ?? this.commentsCurrentPage,
      commentsLastPage: commentsLastPage ?? this.commentsLastPage,
      commentsTotal: commentsTotal ?? this.commentsTotal,
      isLoadingMoreComments:
          isLoadingMoreComments ?? this.isLoadingMoreComments,
      isBusyComment: isBusyComment ?? this.isBusyComment,
      isBusyWord: isBusyWord ?? this.isBusyWord,
    );
  }
}

class LessonDetailError extends LessonDetailState {
  final String message;

  LessonDetailError({required this.message});
}

class DeletingTest extends LessonDetailState {}

class TestDeletedSuccess extends LessonDetailState {
  final String message;

  TestDeletedSuccess({required this.message});
}
