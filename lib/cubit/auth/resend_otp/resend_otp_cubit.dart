import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/repository/auth_repository.dart';
import 'resend_otp_state.dart';

class ResendOtpCubit extends Cubit<ResendOtpState> {
  final AuthRepository authRepository;
  ResendOtpCubit(this.authRepository) : super(ResendOtpInitial());

  Future<void> resendOtp({required String email, required String type}) async {
    emit(ResendOtpLoading());
    print("🟡 [ResendOtpCubit] Resending OTP to: $email, type: $type");

    try {
      final data = await authRepository.resendOtp(email: email, type: type);

      final success = data['success'] as bool? ?? false;
      final message = data['message'] as String? ?? '';

      if (success) {
        print("🎉 [ResendOtpCubit] OTP resent: $message");
        emit(ResendOtpSuccess(message));
      } else {
        print("❌ [ResendOtpCubit] Resend failed: $message");
        emit(ResendOtpFailure(message));
      }
    } catch (e) {
      print("❌ [ResendOtpCubit] Exception: $e");
      emit(ResendOtpFailure(e.toString()));
    }
  }

  void reset() => emit(ResendOtpInitial());
}
