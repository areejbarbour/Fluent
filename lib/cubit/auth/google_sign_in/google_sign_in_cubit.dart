import 'package:fluent/cubit/auth/google_sign_in/google_sign_in_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluent/helper/auth_session.dart';

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

        String roleName = 'student';
        if (roles.isNotEmpty) {
          final role = roles.first;
          if (role is Map) {
            roleName = role['name'] ?? role['title'] ?? 'student';
          } else {
            roleName = role.toString();
          }
        }

        int? uid;
        final rawId = userMap?['id'];
        if (rawId is int) {
          uid = rawId;
        } else if (rawId != null) {
          uid = int.tryParse(rawId.toString());
        }

        await AuthSession.saveSession(
          token: token.toString(),
          role: roleName,
          userId: uid,
          loginMethod: 'google',
        );

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
                print('👤 [GoogleLoginCubit] user_id saved (fallback): $id');
              }
            }
          } catch (e) {
            print(' [GoogleLoginCubit] getCurrentUser fallback failed: $e');
          }
        }

        await setupDio();
        print('✅ [GoogleLoginCubit] Session saved via AuthSession');
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
