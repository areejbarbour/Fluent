import '../../../data/models/lesson_detail_model.dart';

abstract class LessonDetailState {}

class LessonDetailInitial extends LessonDetailState {}

class LessonDetailLoading extends LessonDetailState {}

class LessonDetailSuccess extends LessonDetailState {
  final LessonDetailModel data;
  LessonDetailSuccess(this.data);
}

class LessonDetailFailure extends LessonDetailState {
  final String message;
  LessonDetailFailure(this.message);
}