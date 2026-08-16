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
  dio.interceptors.clear();

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();

        final token = prefs.getString('token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        } else {
          options.headers.remove('Authorization');
        }

        final lang = prefs.getString('app_language') ?? 'en';
        options.headers['Accept-Language'] = lang;

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

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  if (token != null && token.isNotEmpty) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  } else {
    dio.options.headers.remove('Authorization');
  }

  final lang = prefs.getString('app_language') ?? 'en';
  dio.options.headers['Accept-Language'] = lang;

  print('🌐 [Dio] Accept-Language = $lang');
}
