import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/network/dio_client.dart';
import '../../../../data/repository/auth_repository.dart';
import '../../../../helper/auth_session.dart';
import '../../../../helper/notification_bootstrap.dart';
import 'logout_state.dart';

class LogoutCubit extends Cubit<LogoutState> {
  final AuthRepository authRepository;

  LogoutCubit(this.authRepository) : super(LogoutInitial());

  /// Explicit logout: always wipe local session so the user cannot re-enter
  /// the app without signing in again — even if the API call fails.
  Future<void> logout() async {
    emit(LogoutLoading());
    print('🟡 [LogoutCubit] Logging out...');

    String message = 'Logged out';
    try {
      final data = await authRepository.logout();
      final success = data['success'] as bool? ?? false;
      message = data['message']?.toString() ?? message;
      if (!success) {
        print(
          '⚠️ [LogoutCubit] Server logout failed: $message — clearing local anyway',
        );
      } else {
        print('✅ [LogoutCubit] Server logout OK');
      }
    } catch (e) {
      print(
        '⚠️ [LogoutCubit] Server logout exception: $e — clearing local anyway',
      );
      message = 'Logged out';
    }

    // Always clear local session + FCM + Dio auth header
    try {
      await NotificationBootstrap.clearOnLogout();
    } catch (e) {
      print('⚠️ [LogoutCubit] FCM clear: $e');
    }

    await AuthSession.clear();
    await setupDio(); // rebuild interceptors without token

    print('✅ [LogoutCubit] Local session wiped — user must login');
    emit(LogoutSuccess(message));
  }

  void reset() => emit(LogoutInitial());
}
