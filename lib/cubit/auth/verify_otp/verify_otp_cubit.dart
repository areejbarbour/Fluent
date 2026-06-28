import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../data/network/dio_client.dart';
import '../../../../data/repository/auth_repository.dart';
import 'verify_otp_state.dart';

class VerifyOtpCubit extends Cubit<VerifyOtpState> {
  final AuthRepository authRepository;
  VerifyOtpCubit(this.authRepository) : super(VerifyOtpInitial());

  Future<void> verifyOtp({
    required String email,
    required String otp,
    required String type,
  }) async {
    emit(VerifyOtpLoading());
    print("🟡 [VerifyOtpCubit] Verifying OTP for: $email, type: $type");

    try {
      final data = await authRepository.verifyOtp(
        email: email,
        otp: otp,
        type: type,
      );
      print("✅ [VerifyOtpCubit] Response: $data");

      final success = data['success'] as bool? ?? false;
      final message = data['message'] as String? ?? '';

      if (success) {
        final token = data['token'] as String?;
        final user = data['user'] as Map<String, dynamic>?;

        // ✅ حفظ التوكن فقط في حالة REGISTER
        if (token != null && token.isNotEmpty && type == 'register') {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          await prefs.setBool('is_logged_in', true);
          await prefs.setString('login_method', 'email');
          await prefs.setString('user_role', 'student');

          print("🎭 [VerifyOtpCubit] New user role forced to: student");
          print("🔑 [VerifyOtpCubit] Token saved: $token");

          await setupDio();
          print("⚙️ [VerifyOtpCubit] Dio re-initialized");
        }

        print("🎉 [VerifyOtpCubit] Account verified successfully");
        emit(VerifyOtpSuccess(message, token ?? '', user: user));
      } else {
        final errors = data['errors'] as Map<String, dynamic>?;
        print("❌ [VerifyOtpCubit] Verification failed: $message");
        emit(VerifyOtpFailure(message, errors: errors));
      }
    } catch (e) {
      print("❌ [VerifyOtpCubit] Exception: $e");
      emit(VerifyOtpFailure(e.toString()));
    }
  }

  void reset() => emit(VerifyOtpInitial());
}
