abstract class ResendOtpState {}

class ResendOtpInitial extends ResendOtpState {}

class ResendOtpLoading extends ResendOtpState {}

class ResendOtpSuccess extends ResendOtpState {
  final String message;
  ResendOtpSuccess(this.message);
}

class ResendOtpFailure extends ResendOtpState {
  final String error;
  ResendOtpFailure(this.error);
}