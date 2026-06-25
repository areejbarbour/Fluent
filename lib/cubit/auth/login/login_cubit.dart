// lib/presentation/cubits/auth/login/login_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../data/network/dio_client.dart';
import '../../../../data/repository/auth_repository.dart';
import 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthRepository authRepository;

  LoginCubit(this.authRepository) : super(LoginInitial());

  Future<void> login({required String email, required String password}) async {
    emit(LoginLoading());
    print("🟡 [LoginCubit] Logging in: $email");

    try {
      final data = await authRepository.login(email: email, password: password);

      print("✅ [LoginCubit] Response: $data");

      final success = data['success'] as bool? ?? false;
      final message = data['message'] as String? ?? '';

      if (success) {
        final token = data['token'] as String?;
        final roles = data['roles'] as List<dynamic>? ?? [];

        // ✅ حفظ التوكن + الدور
        if (token != null && token.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          await prefs.setBool('is_logged_in', true);
          await prefs.setString('login_method', 'email');

          // ✅ حفظ الدور الأولي
          if (roles.isNotEmpty) {
            final role = roles.first;
            String roleName = '';

            if (role is Map) {
              roleName = role['name'] ?? role['title'] ?? 'student';
            } else {
              roleName = role.toString();
            }

            await prefs.setString('user_role', roleName);
            print("🎭 [LoginCubit] User role saved: $roleName");
          }

          print("🔑 [LoginCubit] Token saved");
          await setupDio();
          print("⚙️ [LoginCubit] Dio re-initialized");
        }

        print("🎉 [LoginCubit] Login successful");
        emit(LoginSuccess(message, token ?? '', roles));
      } else {
        final errors = data['errors'] as Map<String, dynamic>?;
        print("❌ [LoginCubit] Login failed: $message");
        emit(LoginFailure(message, errors: errors));
      }
    } catch (e) {
      print("❌ [LoginCubit] Exception: $e");
      emit(LoginFailure(e.toString()));
    }
  }

  void reset() => emit(LoginInitial());
}
