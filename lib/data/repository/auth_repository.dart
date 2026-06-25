// lib/data/repository/auth_repository.dart
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';

class AuthRepository {
  final AuthService authService;

  AuthRepository(this.authService);

  // 🟢 Save token helper
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // 🟢 Clear token helper
  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // 🟢 Get token helper
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // 🟢 Register
  // في method register فقط - غيرنا طريقة استخراج errors
  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await authService.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

      print("✅ Register Response Status: ${response.statusCode}");
      print("✅ Register Response Data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data is Map<String, dynamic>
            ? {
                'success': true,
                'message': response.data['message'] ?? 'OTP sent successfully',
                'data': response.data,
              }
            : {'success': true, 'message': 'Registration successful'};
      } else {
        final errorData = response.data;
        return {
          'success': false,
          'message': errorData is Map
              ? errorData['message'] ?? 'Registration failed.'
              : 'Registration failed.',
          // ✅ حفظ الـ errors كما هي بدون cast
          'errors': errorData is Map ? errorData['errors'] : null,
        };
      }
    } on DioException catch (e) {
      print("❌ DioException (register): ${e.response?.data}");
      final errorData = e.response?.data;
      return {
        'success': false,
        'message': errorData is Map
            ? errorData['message'] ?? 'Registration failed.'
            : e.message ?? 'Something went wrong.',
        // ✅ حفظ الـ errors كما هي
        'errors': errorData is Map ? errorData['errors'] : null,
      };
    }
  }

  // 🟢 Verify OTP (يحفظ التوكن بعد التحقق الناجح)
  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await authService.verifyOtp(email: email, otp: otp);

      print("✅ VerifyOTP Response Status: ${response.statusCode}");
      print("✅ VerifyOTP Response Data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        // ✅ حفظ التوكن إذا موجود
        if (data is Map && data.containsKey('token')) {
          await _saveToken(data['token']);
        }

        return {
          'success': true,
          'message': data is Map
              ? data['message'] ?? 'Account verified successfully'
              : 'OTP verified successfully',
          'token': data is Map ? data['token'] : null,
          'user': data is Map ? data['user'] : null,
          'data': data,
        };
      } else {
        final errorData = response.data;
        return {
          'success': false,
          'message': errorData is Map
              ? errorData['message'] ?? 'Invalid OTP'
              : 'Invalid OTP',
          'errors': errorData is Map ? errorData['errors'] : null,
        };
      }
    } on DioException catch (e) {
      print("❌ Error verifying OTP: ${e.response?.data}");
      final errorData = e.response?.data;
      return {
        'success': false,
        'message': errorData is Map
            ? errorData['message'] ?? 'Invalid OTP'
            : e.message ?? 'Something went wrong.',
        'errors': errorData is Map ? errorData['errors'] : null,
      };
    }
  }

  // 🟢 Resend OTP
  Future<Map<String, dynamic>> resendOtp({required String email}) async {
    try {
      final response = await authService.resendOtp(email: email);

      print("✅ Resend OTP Response Status: ${response.statusCode}");
      print("✅ Resend OTP Response Data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        return {
          'success': true,
          'message': data is Map
              ? data['message'] ?? 'OTP resent successfully'
              : 'OTP resent successfully',
          'data': data,
        };
      } else {
        final errorData = response.data;
        return {
          'success': false,
          'message': errorData is Map
              ? errorData['message'] ?? 'Resend failed'
              : 'Resend failed',
          'errors': errorData is Map ? errorData['errors'] : null,
        };
      }
    } on DioException catch (e) {
      print("❌ Error resending OTP: ${e.response?.data}");
      final errorData = e.response?.data;
      return {
        'success': false,
        'message': errorData is Map
            ? errorData['message'] ?? 'Resend failed'
            : e.message ?? 'Something went wrong.',
        'errors': errorData is Map ? errorData['errors'] : null,
      };
    }
  }

  // 🟢 Login (يحفظ التوكن)
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await authService.login(
        email: email,
        password: password,
      );

      print("✅ Login Response Status: ${response.statusCode}");
      print("✅ Login Response Data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        // ✅ حفظ التوكن إذا موجود
        if (data is Map && data.containsKey('token')) {
          await _saveToken(data['token']);
        }

        return {
          'success': true,
          'message': data is Map
              ? data['message'] ?? 'Login successful'
              : 'Login successful',
          'token': data is Map ? data['token'] : null,
          'roles': data is Map ? data['role'] : null,
          'data': data,
        };
      } else {
        final errorData = response.data;
        return {
          'success': false,
          'message': errorData is Map
              ? errorData['message'] ?? 'Login failed'
              : 'Login failed',
          'errors': errorData is Map ? errorData['errors'] : null,
        };
      }
    } on DioException catch (e) {
      print("❌ Login DioException: ${e.response?.data}");
      final errorData = e.response?.data;
      return {
        'success': false,
        'message': errorData is Map
            ? errorData['message'] ?? 'Login failed'
            : e.message ?? 'Something went wrong.',
        'errors': errorData is Map ? errorData['errors'] : null,
      };
    }
  }

  // 🟢 Get Current User
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final token = await _getToken();

      if (token == null) {
        return {'success': false, 'message': 'No token found. Please login.'};
      }

      final response = await authService.getCurrentUser(token);

      print("✅ GetCurrentUser Response Status: ${response.statusCode}");
      print("✅ GetCurrentUser Response Data: ${response.data}");

      if (response.statusCode == 200) {
        final data = response.data;
        return {
          'success': true,
          'message': 'User fetched successfully',
          'user': data,
          'data': data,
        };
      } else {
        return {'success': false, 'message': 'Failed to fetch user data'};
      }
    } on DioException catch (e) {
      print("❌ GetCurrentUser DioException: ${e.response?.data}");
      return {
        'success': false,
        'message': e.message ?? 'Failed to fetch user data',
      };
    }
  }

  // 🟢 Logout
  Future<Map<String, dynamic>> logout() async {
    try {
      final token = await _getToken();

      print('🔑 Logout token: $token');

      if (token == null) {
        return {'success': true, 'message': 'Already logged out.'};
      }

      final response = await authService.logout(token);

      print("✅ Logout Response Status: ${response.statusCode}");
      print("✅ Logout Response Data: ${response.data}");

      // ✅ مسح التوكن محلياً بغض النظر عن حالة الاستجابة
      await _clearToken();

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': response.data is Map
              ? response.data['message'] ?? 'Logged out successfully'
              : 'Logged out successfully',
        };
      } else {
        return {
          'success': true, // نعتبرها ناجحة لأننا مسحنا التوكن محلياً
          'message': response.data is Map
              ? response.data['message'] ?? 'Logged out locally'
              : 'Logged out locally',
        };
      }
    } on DioException catch (e) {
      print('❌ Logout DioException: ${e.response?.data}');

      // ✅ مسح التوكن محلياً حتى لو فشل الطلب
      await _clearToken();

      return {
        'success': true, // نعتبرها ناجحة لأننا مسحنا التوكن محلياً
        'message': 'Logged out locally (server unreachable)',
      };
    } catch (e) {
      print('❌ Unexpected logout error: $e');
      await _clearToken();
      return {'success': true, 'message': 'Logged out locally'};
    }
  }
}
