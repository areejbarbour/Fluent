import 'package:fluent/cubit/auth/google_sign_in/google_sign_in_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/network/dio_client.dart';
import '../../../data/repository/auth_repository.dart';

class GoogleLoginCubit extends Cubit<GoogleLoginState> {
  final AuthRepository authRepository;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  GoogleLoginCubit(this.authRepository) : super(GoogleLoginInitial());

  Future<void> loginWithGoogle() async {
    emit(GoogleLoginLoading());
    print("⏳ Google login process started");

    try {
      // تسجيل الخروج من حساب قديم لتجنب الدخول التلقائي
      await _googleSignIn.signOut();

      final user = await _googleSignIn.signIn();

      if (user == null) {
        print("❌ Google Sign-In was cancelled by the user");
        emit(const GoogleLoginFailure('Google Sign-In was cancelled'));
        return;
      }

      print("✅ Google user selected: ${user.email}");

      final googleAuth = await user.authentication;
      final accessToken = googleAuth.accessToken;

      if (accessToken == null) {
        print("❌ Failed to retrieve access token from GoogleAuth");
        emit(const GoogleLoginFailure('Failed to retrieve access token'));
        return;
      }

      print("🔐 Access token received: $accessToken");

      final response = await authRepository.googleLogin(token: accessToken);
      print("📡 Received response from backend: $response");

      if (response['success'] == true) {
        final token = response['token'];
        final user = response['user'] as Map<String, dynamic>?;
        final roles = response['roles'] as List<dynamic>? ?? [];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('login_method', 'google');

        // ✅ حفظ role
        if (roles.isNotEmpty) {
          final role = roles.first;
          String roleName = '';

          if (role is Map) {
            roleName = role['name'] ?? role['title'] ?? 'student';
          } else {
            roleName = role.toString();
          }

          await prefs.setString('user_role', roleName);
          print("🎭 [GoogleLoginCubit] Role saved: $roleName");
        }

        // 🔑 أعد تجهيز Dio بالتوكن الجديد!
        await setupDio();
        print("✅ Token stored in SharedPreferences: $token");

        emit(GoogleLoginSuccess(token: token, roles: roles, user: user));
        print("🎉 GoogleLoginSuccess emitted");
      } else {
        final errorMsg = response['message'] ?? 'Google login failed';
        print("❌ Backend login failed: $errorMsg");
        emit(GoogleLoginFailure(errorMsg));
      }
    } catch (e) {
      print("❌ Unexpected error occurred during Google login: $e");
      emit(const GoogleLoginFailure('An unexpected error occurred'));
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}