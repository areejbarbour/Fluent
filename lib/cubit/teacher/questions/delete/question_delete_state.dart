
abstract class QuestionDeleteState {}

class QuestionDeleteInitial extends QuestionDeleteState {}

class QuestionDeleteLoading extends QuestionDeleteState {}

class QuestionDeleteSuccess extends QuestionDeleteState {
  final String message;
  QuestionDeleteSuccess(this.message);
}

class QuestionDeleteFailure extends QuestionDeleteState {
  final String error;
  final Map<String, dynamic>? errors;
  QuestionDeleteFailure(this.error, {this.errors});
}