
import 'package:fluent/data/models/question_status_model.dart';

abstract class QuestionStatusState {}

class QuestionStatusInitial extends QuestionStatusState {}

class QuestionStatusLoading extends QuestionStatusState {}

class QuestionStatusLoaded extends QuestionStatusState {
  final QuestionStatus status;
  QuestionStatusLoaded(this.status);
}

class QuestionStatusFailure extends QuestionStatusState {
  final String error;
  final Map<String, dynamic>? errors;
  QuestionStatusFailure(this.error, {this.errors});
}