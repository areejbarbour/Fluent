// lib/presentation/cubits/auth/login/login_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../data/network/dio_client.dart';
import '../../../../data/repository/auth_repository.dart';
import '../../../../helper/notification_bootstrap.dart';
import 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthRepository authRepository;

  LoginCubit(this.authRepository) : super(LoginInitial());

  Future<void> login({required String email, required String password}) async {
    emit(LoginLoading());
    print(" [LoginCubit] Logging in: $email");

    try {
      final data = await authRepository.login(email: email, password: password);

      print(" [LoginCubit] Response: $data");

      final success = data['success'] as bool? ?? false;
      final message = data['message'] as String? ?? '';

      if (success) {
        final token = data['token'] as String?;

        List<dynamic> roles = [];
        if (data['roles'] != null && (data['roles'] as List).isNotEmpty) {
          roles = data['roles'] as List<dynamic>;
        } else if (data['role'] != null) {
          final r = data['role'];
          roles = r is List ? r as List<dynamic> : [r];
        } else if (data['user']?['roles'] != null) {
          roles = data['user']['roles'] as List<dynamic>;
        } else if (data['data']?['role'] != null) {
          final r = data['data']['role'];
          roles = r is List ? r as List<dynamic> : [r];
        }

        print(" [LoginCubit] Extracted roles: $roles");

        if (token != null && token.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          await prefs.setBool('is_logged_in', true);
          await prefs.setString('login_method', 'email');

          if (roles.isNotEmpty) {
            final role = roles.first;
            String roleName = '';

            if (role is Map) {
              roleName = role['name'] ?? role['title'] ?? 'student';
            } else {
              roleName = role.toString();
            }

            await prefs.setString('user_role', roleName);
            print(" [LoginCubit] User role saved: $roleName");
          } else {
            await prefs.setString('user_role', 'student');
            print(" [LoginCubit] No role found, defaulting to 'student'");
          }

          Map<String, dynamic>? userMap;
          if (data['user'] is Map) {
            userMap = Map<String, dynamic>.from(data['user'] as Map);
          } else if (data['data'] is Map &&
              (data['data'] as Map)['user'] is Map) {
            userMap = Map<String, dynamic>.from(
              (data['data'] as Map)['user'] as Map,
            );
          }
          await _saveUserId(prefs, userMap);

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
              print(" [LoginCubit] getCurrentUser fallback failed: $e");
            }
          }

          print(" [LoginCubit] Token saved");
          await setupDio();
          print("⚙️ [LoginCubit] Dio re-initialized");

          // Register FCM token immediately after login
          await NotificationBootstrap.registerAfterAuth();
        }

        print(" [LoginCubit] Login successful");
        emit(LoginSuccess(message, token ?? '', roles));
      } else {
        final errors = data['errors'] as Map<String, dynamic>?;
        print(" [LoginCubit] Login failed: $message");
        emit(LoginFailure(message, errors: errors));
      }
    } catch (e) {
      print(" [LoginCubit] Exception: $e");
      emit(LoginFailure(e.toString()));
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
      print("👤 [LoginCubit] user_id saved: $id");
    }
  }

  void reset() => emit(LoginInitial());
}
