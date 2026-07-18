import 'package:dio/dio.dart';
import 'package:fluent/constants/strings.dart';

class AuthService {
  final Dio dio;
  AuthService(this.dio);

  // ✅ Register
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

  Future<Response> verifyOtp({
    required String email,
    required String otp,
    required String type,
  }) async {
    return await dio.post(
      apiVerifyOtp(type),
      data: FormData.fromMap({'email': email, 'otp': otp}),
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  Future<Response> resendOtp({
    required String email,
    required String type,
  }) async {
    return await dio.post(
      apiResendOtp(type),
      data: FormData.fromMap({'email': email}),
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  // ✅ Login
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

  // ✅ Logout
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

  // ✅ Get Current User
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

  // ✅ Forgot Password
  Future<Response> forgotPassword({required String email}) async {
    return await dio.post(
      apiForgotPassword,
      data: FormData.fromMap({'email': email}),
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  // ✅ Reset Password
  Future<Response> resetPassword({
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    return await dio.post(
      apiResetPassword,
      data: FormData.fromMap({
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

  Future<Response> loginWithGoogleToken(String token) async {
    return await dio.post(
      '/api/google/login', // ✅ المسار الصحيح
      data: FormData.fromMap({'access_token': token}), // ✅ في body وليس query
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }
}
