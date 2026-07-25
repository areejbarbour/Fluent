import 'package:dio/dio.dart';
import 'package:fluent/constants/strings.dart';

class TestService {
  final Dio dio;
  TestService(this.dio);

  // ✅ نستخدم نفس المسار /api/tests ولكن بـ GET method لجلب القائمة
  Future<Response> getTeacherTests() async {
    return await dio.get(
      '/api/tests',
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  Future<Response> createTest(FormData formData) async {
    return await dio.post(
      '/api/tests', // نفس المسار الموجود في الباك اند
      data: formData,
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  Future<Response> updateTest(int testId, FormData formData) async {
    return await dio.post(
      '/api/tests/$testId', // ✅ المسار الصحيح حسب الباك إند
      data: formData,
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  Future<Response> getTestById(int testId) async {
    // ✅ جديد
    return await dio.get(
      '/api/tests/$testId',
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  // ✅ جديد: حذف الاختبار
  Future<Response> deleteTest(int testId) async {
    return await dio.delete(
      '/api/tests/$testId',
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  // Service
  Future<Response> getAllTests() async {
    return await dio.get(
      apiTests,
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (s) => s != null && s < 500,
      ),
    );
  }
}
