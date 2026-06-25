// lib/presentation/cubits/auth/verify_otp/verify_otp_state.dart
abstract class VerifyOtpState {}

class VerifyOtpInitial extends VerifyOtpState {}

class VerifyOtpLoading extends VerifyOtpState {}

class VerifyOtpSuccess extends VerifyOtpState {
  final String message;
  final String token;
  final Map<String, dynamic>? user;

  VerifyOtpSuccess(this.message, this.token, {this.user});
}

class VerifyOtpFailure extends VerifyOtpState {
  final String error;
  final Map<String, dynamic>? errors; // ✅ غيرنا النوع

  VerifyOtpFailure(this.error, {this.errors});
}
