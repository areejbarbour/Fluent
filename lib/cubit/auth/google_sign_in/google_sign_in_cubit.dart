import 'package:fluent/cubit/auth/google_sign_in/google_sign_in_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/network/dio_client.dart';
import '../../../data/repository/auth_repository.dart';
import '../../../helper/notification_bootstrap.dart';

class GoogleLoginCubit extends Cubit<GoogleLoginState> {
  final AuthRepository authRepository;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  GoogleLoginCubit(this.authRepository) : super(GoogleLoginInitial());

  Future<void> loginWithGoogle() async {
    emit(GoogleLoginLoading());
    print(" Google login process started");

    try {
      await _googleSignIn.signOut();

      final user = await _googleSignIn.signIn();

      if (user == null) {
        print(" Google Sign-In was cancelled by the user");
        emit(const GoogleLoginFailure('Google Sign-In was cancelled'));
        return;
      }

      print(" Google user selected: ${user.email}");

      final googleAuth = await user.authentication;
      final accessToken = googleAuth.accessToken;

      if (accessToken == null) {
        print(" Failed to retrieve access token from GoogleAuth");
        emit(const GoogleLoginFailure('Failed to retrieve access token'));
        return;
      }

      print(" Access token received: $accessToken");

      final response = await authRepository.googleLogin(token: accessToken);
      print(" Received response from backend: $response");

      if (response['success'] == true) {
        final token = response['token'];
        final userMap = response['user'] as Map<String, dynamic>?;
        final roles = response['roles'] as List<dynamic>? ?? [];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('login_method', 'google');

        if (roles.isNotEmpty) {
          final role = roles.first;
          String roleName = '';

          if (role is Map) {
            roleName = role['name'] ?? role['title'] ?? 'student';
          } else {
            roleName = role.toString();
          }

          await prefs.setString('user_role', roleName);
          print(" [GoogleLoginCubit] Role saved: $roleName");
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
            print(" [GoogleLoginCubit] getCurrentUser fallback failed: $e");
          }
        }

        await setupDio();
        print(" Token stored in SharedPreferences: $token");

        // Register FCM token immediately after Google login
        await NotificationBootstrap.registerAfterAuth();

        emit(GoogleLoginSuccess(token: token, roles: roles, user: userMap));
        print(" GoogleLoginSuccess emitted");
      } else {
        final errorMsg = response['message'] ?? 'Google login failed';
        print(" Backend login failed: $errorMsg");
        emit(GoogleLoginFailure(errorMsg));
      }
    } catch (e) {
      print(" Unexpected error occurred during Google login: $e");
      emit(const GoogleLoginFailure('An unexpected error occurred'));
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
      print("👤 [GoogleLoginCubit] user_id saved: $id");
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}
