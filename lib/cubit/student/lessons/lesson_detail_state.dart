import '../../../data/models/lesson_detail_model.dart';

abstract class LessonDetailState {}

class LessonDetailInitial extends LessonDetailState {}

class LessonDetailLoading extends LessonDetailState {}

class LessonDetailSuccess extends LessonDetailState {
  final LessonDetailModel data;
  final bool isLoadingMore;

  LessonDetailSuccess(this.data, {this.isLoadingMore = false});

  LessonDetailSuccess copyWith({
    LessonDetailModel? data,
    bool? isLoadingMore,
  }) {
    return LessonDetailSuccess(
      data ?? this.data,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class LessonDetailFailure extends LessonDetailState {
  final String message;
  LessonDetailFailure(this.message);
}
