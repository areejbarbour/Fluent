// lib/presentation/cubits/auth/login/login_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluent/helper/auth_session.dart';

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
          String roleName = 'student';
          if (roles.isNotEmpty) {
            final role = roles.first;
            if (role is Map) {
              roleName = role['name'] ?? role['title'] ?? 'student';
            } else {
              roleName = role.toString();
            }
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

          int? uid;
          final rawId = userMap?['id'];
          if (rawId is int) {
            uid = rawId;
          } else if (rawId != null) {
            uid = int.tryParse(rawId.toString());
          }

          await AuthSession.saveSession(
            token: token,
            role: roleName,
            userId: uid,
            loginMethod: 'email',
          );

          // Fallback user_id from /user if missing
          if (await AuthSession.userId() == null) {
            try {
              final me = await authRepository.getCurrentUser();
              if (me['success'] == true) {
                final u = me['user'];
                Map<String, dynamic>? um;
                if (u is Map<String, dynamic>) {
                  um = u;
                } else if (u is Map) {
                  um = Map<String, dynamic>.from(u);
                }
                final rid = um?['id'];
                final id = rid is int ? rid : int.tryParse('$rid');
                if (id != null && id > 0) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setInt(AuthSession.userIdKey, id);
                  print('👤 [LoginCubit] user_id saved (fallback): $id');
                }
              }
            } catch (e) {
              print(' [LoginCubit] getCurrentUser fallback failed: $e');
            }
          }

          print(' [LoginCubit] Session saved via AuthSession');
          await setupDio();
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
