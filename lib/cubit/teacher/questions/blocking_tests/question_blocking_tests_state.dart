
import 'package:fluent/data/models/question_status_model.dart';

abstract class QuestionBlockingTestsState {}

class QuestionBlockingTestsInitial extends QuestionBlockingTestsState {}

class QuestionBlockingTestsLoading extends QuestionBlockingTestsState {}

class QuestionBlockingTestsLoaded extends QuestionBlockingTestsState {
  final BlockingTests data;
  QuestionBlockingTestsLoaded(this.data);
}

class QuestionBlockingTestsFailure extends QuestionBlockingTestsState {
  final String error;
  final Map<String, dynamic>? errors;
  QuestionBlockingTestsFailure(this.error, {this.errors});
} 