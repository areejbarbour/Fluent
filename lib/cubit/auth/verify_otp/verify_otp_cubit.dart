import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/cubit/safe_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../data/network/dio_client.dart';
import '../../../../data/repository/auth_repository.dart';
import '../../../../helper/notification_bootstrap.dart';
import 'verify_otp_state.dart';

class VerifyOtpCubit extends SafeCubit<VerifyOtpState> {
  final AuthRepository authRepository;
  VerifyOtpCubit(this.authRepository) : super(VerifyOtpInitial());

  Future<void> verifyOtp({
    required String email,
    required String otp,
    required String type,
  }) async {
    emit(VerifyOtpLoading());
    print(" [VerifyOtpCubit] Verifying OTP for: $email, type: $type");

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

        if (token != null && token.isNotEmpty && type == 'register') {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          await prefs.setBool('is_logged_in', true);
          await prefs.setString('login_method', 'email');
          await prefs.setString('user_role', 'student');

          await _saveUserId(prefs, user);
          if (prefs.getInt('user_id') == null || prefs.getInt('user_id') == 0) {
            try {
              final me = await authRepository.getCurrentUser();
              if (me['success'] == true) {
                final u = me['user'];
                if (u is Map<String, dynamic>) {
                  await _saveUserId(prefs, u);
                } else if (u is Map) {
                  await _saveUserId(prefs, Map<String, dynamic>.from(u));
                }
              }
            } catch (e) {
              print(" [VerifyOtpCubit] getCurrentUser fallback failed: $e");
            }
          }

          print(" [VerifyOtpCubit] New user role forced to: student");
          print(" [VerifyOtpCubit] Token saved: $token");

          await setupDio();
          print("⚙️ [VerifyOtpCubit] Dio re-initialized");

          await NotificationBootstrap.registerAfterAuth();
        }

        print(" [VerifyOtpCubit] Account verified successfully");
        emit(VerifyOtpSuccess(message, token ?? '', user: user));
      } else {
        final errors = data['errors'] as Map<String, dynamic>?;
        print(" [VerifyOtpCubit] Verification failed: $message");
        emit(VerifyOtpFailure(message, errors: errors));
      }
    } catch (e) {
      print(" [VerifyOtpCubit] Exception: $e");
      emit(VerifyOtpFailure(e.toString()));
    }
  }

  Future<void> _saveUserId(
    SharedPreferences prefs,
    Map<String, dynamic>? user,
  ) async {
    if (user == null) return;
    final raw = user['id'];
    if (raw == null) return;
    final id = raw is int ? raw : int.tryParse(raw.toString());
    if (id != null && id > 0) {
      await prefs.setInt('user_id', id);
      print("👤 [VerifyOtpCubit] user_id saved: $id");
    }
  }

  void reset() => emit(VerifyOtpInitial());
}
