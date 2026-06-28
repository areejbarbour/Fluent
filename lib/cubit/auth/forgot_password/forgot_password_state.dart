abstract class ForgotPasswordState {}

class ForgotPasswordInitial extends ForgotPasswordState {}

class ForgotPasswordLoading extends ForgotPasswordState {}

class ForgotPasswordSuccess extends ForgotPasswordState {
  final String message;
  ForgotPasswordSuccess(this.message);
}

class ForgotPasswordFailure extends ForgotPasswordState {
  final String error;
  final Map<String, dynamic>? errors;
  ForgotPasswordFailure(this.error, {this.errors});
}
