// lib/data/services/auth_service.dart
import 'package:dio/dio.dart';
import 'package:fluent/constants/strings.dart';

class AuthService {
  final Dio dio;

  AuthService(this.dio);

  // ✅ Register - إنشاء حساب جديد
  Future<Response> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    return await dio.post(
      apiRegister,
      data: FormData.fromMap({
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  // ✅ Verify OTP - التحقق من رمز التحقق
  Future<Response> verifyOtp({
    required String email,
    required String otp,
  }) async {
    return await dio.post(
      apiVerifyOtp,
      data: FormData.fromMap({'email': email, 'otp': otp}),
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  // ✅ Resend OTP - إعادة إرسال رمز التحقق
  Future<Response> resendOtp({required String email}) async {
    return await dio.post(
      apiResendOtp,
      data: FormData.fromMap({'email': email}),
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  // ✅ Login - تسجيل الدخول
  Future<Response> login({
    required String email,
    required String password,
  }) async {
    return await dio.post(
      apiLogin,
      data: FormData.fromMap({'email': email, 'password': password}),
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  // ✅ Logout - تسجيل الخروج
  Future<Response> logout(String token) async {
    return await dio.post(
      apiLogout,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  // ✅ Get Current User - جلب بيانات المستخدم الحالي
  Future<Response> getCurrentUser(String token) async {
    return await dio.get(
      apiCurrentUser,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }
}
