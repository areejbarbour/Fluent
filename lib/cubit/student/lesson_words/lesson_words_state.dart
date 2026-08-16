import 'package:fluent/data/models/lesson_word_model.dart';

abstract class LessonWordsState {}

class LessonWordsInitial extends LessonWordsState {}

class LessonWordsLoading extends LessonWordsState {}

class LessonWordsSuccess extends LessonWordsState {
  final List<LessonWordModel> words;
  final int? busyWordId;

  LessonWordsSuccess(this.words, {this.busyWordId});
}

class LessonWordsFailure extends LessonWordsState {
  final String message;
  LessonWordsFailure(this.message);
}

class LessonWordsActionSuccess extends LessonWordsState {
  final String message;
  final List<LessonWordModel> words;
  LessonWordsActionSuccess({required this.message, required this.words});
}
