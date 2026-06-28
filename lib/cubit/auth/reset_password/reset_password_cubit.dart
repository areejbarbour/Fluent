import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/repository/auth_repository.dart';
import 'reset_password_state.dart';

class ResetPasswordCubit extends Cubit<ResetPasswordState> {
  final AuthRepository authRepository;
  ResetPasswordCubit(this.authRepository) : super(ResetPasswordInitial());

  Future<void> resetPassword({
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    emit(ResetPasswordLoading());
    print("🟡 [ResetPasswordCubit] Resetting password for: $email");

    try {
      final data = await authRepository.resetPassword(
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

      final success = data['success'] as bool? ?? false;
      final message = data['message'] as String? ?? '';

      if (success) {
        print("🎉 [ResetPasswordCubit] Password reset: $message");
        emit(ResetPasswordSuccess(message));
      } else {
        final errors = data['errors'] as Map<String, dynamic>?;
        print("❌ [ResetPasswordCubit] Failed: $message");
        emit(ResetPasswordFailure(message, errors: errors));
      }
    } catch (e) {
      print("❌ [ResetPasswordCubit] Exception: $e");
      emit(ResetPasswordFailure(e.toString()));
    }
  }

  void reset() => emit(ResetPasswordInitial());
}
