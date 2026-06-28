abstract class ResetPasswordState {}

class ResetPasswordInitial extends ResetPasswordState {}

class ResetPasswordLoading extends ResetPasswordState {}

class ResetPasswordSuccess extends ResetPasswordState {
  final String message;
  ResetPasswordSuccess(this.message);
}

class ResetPasswordFailure extends ResetPasswordState {
  final String error;
  final Map<String, dynamic>? errors;
  ResetPasswordFailure(this.error, {this.errors});
}
