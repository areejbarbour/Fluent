import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/repository/auth_repository.dart';
import 'forgot_password_state.dart';

class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  final AuthRepository authRepository;
  ForgotPasswordCubit(this.authRepository) : super(ForgotPasswordInitial());

  Future<void> forgotPassword({required String email}) async {
    emit(ForgotPasswordLoading());
    print("🟡 [ForgotPasswordCubit] Sending OTP to: $email");
    
    try {
      final data = await authRepository.forgotPassword(email: email);
      
      final success = data['success'] as bool? ?? false;
      final message = data['message'] as String? ?? '';

      if (success) {
        print("🎉 [ForgotPasswordCubit] OTP sent: $message");
        emit(ForgotPasswordSuccess(message));
      } else {
        final errors = data['errors'] as Map<String, dynamic>?;
        print("❌ [ForgotPasswordCubit] Failed: $message");
        emit(ForgotPasswordFailure(message, errors: errors));
      }
    } catch (e) {
      print("❌ [ForgotPasswordCubit] Exception: $e");
      emit(ForgotPasswordFailure(e.toString()));
    }
  }

  void reset() => emit(ForgotPasswordInitial());
}