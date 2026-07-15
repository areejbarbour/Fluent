
import 'package:fluent/data/models/question_model.dart';

abstract class QuestionDetailState {}

class QuestionDetailInitial extends QuestionDetailState {}

class QuestionDetailLoading extends QuestionDetailState {}

class QuestionDetailLoaded extends QuestionDetailState {
  final Question question;
  QuestionDetailLoaded(this.question);
}

class QuestionDetailFailure extends QuestionDetailState {
  final String error;
  final Map<String, dynamic>? errors;
  QuestionDetailFailure(this.error, {this.errors});
}