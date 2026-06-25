// lib/presentation/cubits/auth/logout/logout_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../data/network/dio_client.dart';
import '../../../../data/repository/auth_repository.dart';
import 'logout_state.dart';

class LogoutCubit extends Cubit<LogoutState> {
  final AuthRepository authRepository;

  LogoutCubit(this.authRepository) : super(LogoutInitial());

  Future<void> logout() async {
    emit(LogoutLoading());
    print("🟡 [LogoutCubit] Logging out...");

    try {
      final data = await authRepository.logout();

      final success = data['success'] as bool? ?? false;
      final message = data['message'] as String? ?? '';

      if (success) {
        // ✅ مسح SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        await prefs.remove('is_logged_in');
        await prefs.remove('login_method');
        await prefs.remove('user_role'); // ✅ مسح الدور
        print("🧹 [LogoutCubit] SharedPreferences cleared");

        // ✅ إعادة setup Dio بدون token
        await setupDio();
        print("⚙️ [LogoutCubit] Dio re-initialized without token");

        print("🎉 [LogoutCubit] Logout successful");
        emit(LogoutSuccess(message));
      } else {
        print("❌ [LogoutCubit] Logout failed: $message");
        emit(LogoutFailure(message));
      }
    } catch (e) {
      print("❌ [LogoutCubit] Exception: $e");
      emit(LogoutFailure(e.toString()));
    }
  }

  void reset() => emit(LogoutInitial());
}
