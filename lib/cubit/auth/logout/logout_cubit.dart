import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/cubit/safe_cubit.dart';

import '../../../../data/network/dio_client.dart';
import '../../../../data/repository/auth_repository.dart';
import '../../../../helper/auth_session.dart';
import '../../../../helper/notification_bootstrap.dart';
import 'logout_state.dart';

class LogoutCubit extends SafeCubit<LogoutState> {
  final AuthRepository authRepository;

  LogoutCubit(this.authRepository) : super(LogoutInitial());

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

    try {
      await NotificationBootstrap.clearOnLogout();
    } catch (e) {
      print('⚠️ [LogoutCubit] FCM clear: $e');
    }

    await AuthSession.clear();
    await setupDio();

    print('✅ [LogoutCubit] Local session wiped — user must login');
    emit(LogoutSuccess(message));
  }

  void reset() => emit(LogoutInitial());
}
