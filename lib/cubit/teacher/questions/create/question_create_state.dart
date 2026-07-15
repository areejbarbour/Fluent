
import 'package:fluent/data/models/question_model.dart';

abstract class QuestionCreateState {}

class QuestionCreateInitial extends QuestionCreateState {}

class QuestionCreateLoading extends QuestionCreateState {}

class QuestionCreateSuccess extends QuestionCreateState {
  final Question question;
  final String message;
  QuestionCreateSuccess(this.question, this.message);
}

class QuestionCreateFailure extends QuestionCreateState {
  final String error;
  final Map<String, dynamic>? errors;
  QuestionCreateFailure(this.error, {this.errors});
} 