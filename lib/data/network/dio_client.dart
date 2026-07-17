import 'package:dio/dio.dart';
import 'package:fluent/constants/strings.dart';
import 'package:shared_preferences/shared_preferences.dart';

final dio = Dio(
  BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ),
);

Future<void> setupDio() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  dio.interceptors.clear();

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        print("➡️ [REQUEST]");
        print("URL: ${options.uri}");
        print("METHOD: ${options.method}");
        print("HEADERS: ${options.headers}");
        print("DATA: ${options.data}");
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print("⬅️ [RESPONSE]");
        print("STATUS: ${response.statusCode}");
        print("HEADERS: ${response.headers}");
        print("DATA: ${response.data}");
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        print("❌ [ERROR]");
        print("MESSAGE: ${e.message}");
        if (e.response != null) {
          print("STATUS: ${e.response?.statusCode}");
          print("DATA: ${e.response?.data}");
        }
        return handler.next(e);
      },
    ),
  );

  // ✅ إضافة التوكن إذا موجود
  if (token != null && token.isNotEmpty) {
    print('🔑 [Dio] Adding Authorization header with token: $token');
    dio.options.headers['Authorization'] = 'Bearer $token';
  } else {
    dio.options.headers.remove('Authorization'); // ✅ هاد الناقص
    print('⚠️ [Dio] No token found, Authorization header not added');
  }
}


