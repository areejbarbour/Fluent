import 'package:dio/dio.dart';
import 'package:fluent/constants/strings.dart';

class TestService {
  final Dio dio;
  TestService(this.dio);

  Future<Response> getTeacherTests() async {
    return await dio.get(
      apiTests,
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  /// POST /api/tests — JSON body (no files on CreateTestRequest).
  Future<Response> createTest(Map<String, dynamic> payload) async {
    return await dio.post(
      apiTests,
      data: payload,
      options: Options(
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  /// POST /api/tests/{test} — JSON body (matches backend update route).
  Future<Response> updateTest(int testId, Map<String, dynamic> payload) async {
    return await dio.post(
      apiTestDetail(testId),
      data: payload,
      options: Options(
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  Future<Response> getTestById(int testId) async {
    return await dio.get(
      apiTestDetail(testId),
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  Future<Response> deleteTest(int testId) async {
    return await dio.delete(
      apiTestDetail(testId),
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

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
