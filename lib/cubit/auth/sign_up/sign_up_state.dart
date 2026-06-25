// lib/presentation/cubits/auth/sign_up/sign_up_state.dart
abstract class SignUpState {}

class SignUpInitial extends SignUpState {}

class SignUpLoading extends SignUpState {}

class SignUpSuccess extends SignUpState {
  final String message;
  SignUpSuccess(this.message);
}

class SignUpFailure extends SignUpState {
  final String error;
  // ✅ غيرنا النوع من Map<String, List<String>>? إلى Map<String, dynamic>?
  final Map<String, dynamic>? errors;

  SignUpFailure(this.error, {this.errors});
}
