// lib/presentation/cubits/auth/sign_up/sign_up_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/repository/auth_repository.dart';
import 'sign_up_state.dart';

class SignUpCubit extends Cubit<SignUpState> {
  final AuthRepository authRepository;

  SignUpCubit(this.authRepository) : super(SignUpInitial());

  Future<void> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    emit(SignUpLoading());
    print("🟡 [SignUpCubit] Starting sign up process...");

    try {
      print("📨 [SignUpCubit] Sending registration request...");
      final data = await authRepository.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

      print("✅ [SignUpCubit] Response received: $data");

      final success = data['success'] as bool? ?? false;
      final message = data['message'] as String? ?? '';

      final errors = data['errors'] as Map<String, dynamic>?;

      if (success) {
        print("🎉 [SignUpCubit] Registration successful: $message");
        print("📧 [SignUpCubit] Navigate to OTP verification screen");
        emit(SignUpSuccess(message));
      } else {
        print("❌ [SignUpCubit] Registration failed: $message");
        emit(SignUpFailure(message, errors: errors));
      }
    } catch (e) {
      print("❌ [SignUpCubit] Exception: $e");
      emit(SignUpFailure(e.toString()));
    }
  }

  void reset() => emit(SignUpInitial());
}
