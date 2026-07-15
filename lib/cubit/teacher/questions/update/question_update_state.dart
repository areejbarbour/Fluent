
import 'package:fluent/data/models/question_model.dart';

abstract class QuestionUpdateState {}

class QuestionUpdateInitial extends QuestionUpdateState {}

class QuestionUpdateLoading extends QuestionUpdateState {}

class QuestionUpdateSuccess extends QuestionUpdateState {
  final String status; // 'versioned' or 'updated'
  final String message;
  final Question? question;

  QuestionUpdateSuccess({
    required this.status,
    required this.message,
    this.question,
  });

  bool get wasVersioned => status == 'versioned';
}

class QuestionUpdateFailure extends QuestionUpdateState {
  final String error;
  final Map<String, dynamic>? errors;
  QuestionUpdateFailure(this.error, {this.errors});
}