abstract class LoginState {}

class LoginInitial extends LoginState {}

class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {
  final String message;
  final String token;
  final List<dynamic> roles;

  LoginSuccess(this.message, this.token, this.roles);
}

class LoginFailure extends LoginState {
  final String error;
  final Map<String, dynamic>? errors; // ✅ غيرنا النوع

  LoginFailure(this.error, {this.errors});
}
