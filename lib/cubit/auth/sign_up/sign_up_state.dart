abstract class SignUpState {}

class SignUpInitial extends SignUpState {}

class SignUpLoading extends SignUpState {}

class SignUpSuccess extends SignUpState {
  final String message;
  SignUpSuccess(this.message);
}

class SignUpFailure extends SignUpState {
  final String error;
  final Map<String, dynamic>? errors;

  SignUpFailure(this.error, {this.errors});
}
