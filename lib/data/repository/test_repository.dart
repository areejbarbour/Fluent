import 'package:dio/dio.dart';
import 'package:fluent/data/models/test_model.dart';
import 'package:fluent/data/services/test_service.dart';

class TestRepository {
  final TestService testService;
  TestRepository(this.testService);

  Future<Map<String, dynamic>> getTeacherTests() async {
    try {
      final response = await testService.getTeacherTests();
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['data'] is List) {
          final tests = (data['data'] as List)
              .whereType<Map>()
              .map((e) => TestModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          return {'success': true, 'data': tests};
        }
      }
      return {
        'success': false,
        'message': _extractMessage(response.data, 'Failed to load tests'),
      };
    } on DioException catch (e) {
      return _errorPayload(e);
    }
  }

  String _extractMessage(dynamic data, String fallback) {
    if (data is! Map) return fallback;
    final errors = data['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final firstValue = errors.values.first;
      if (firstValue is List && firstValue.isNotEmpty)
        return firstValue.first.toString();
      if (firstValue is String) return firstValue;
    }
    return data['message'] is String ? data['message'] as String : fallback;
  }

  Map<String, dynamic> _errorPayload(DioException e) {
    final data = e.response?.data;
    return {
      'success': false,
      'message': _extractMessage(data, e.message ?? 'Request failed'),
      'errors': data is Map ? data['errors'] : null,
    };
  }

  Future<Map<String, dynamic>> createTest(FormData formData) async {
    try {
      final response = await testService.createTest(formData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        return {
          'success': true,
          'data': data is Map<String, dynamic> ? (data['data'] ?? data) : data,
        };
      }
      final err = response.data;
      return {
        'success': false,
        'message': _extractMessage(err, 'Failed to create test'),
        'errors': err is Map ? err['errors'] : null,
      };
    } on DioException catch (e) {
      return _errorPayload(e);
    }
  }

  Future<Map<String, dynamic>> updateTest(int testId, FormData formData) async {
    try {
      final response = await testService.updateTest(testId, formData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        return {
          'success': true,
          'data': data is Map<String, dynamic> ? (data['data'] ?? data) : data,
          'message': data['message'] ?? 'Test updated successfully',
        };
      }
      final err = response.data;
      return {
        'success': false,
        'message': _extractMessage(err, 'Failed to update test'),
        'errors': err is Map ? err['errors'] : null,
      };
    } on DioException catch (e) {
      return _errorPayload(e);
    }
  }

  Future<Map<String, dynamic>> getTestById(int testId) async {
    try {
      final response = await testService.getTestById(testId);
      print(
        '🔍 repo raw response: ${response.statusCode} | ${response.data}',
      ); // ✅
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final raw = data is Map<String, dynamic>
            ? (data['data'] ?? data)
            : data;
        print('🔍 raw to parse: $raw'); // ✅
        final model = TestModel.fromJson(Map<String, dynamic>.from(raw));
        print('🔍 parsed model id: ${model.id}'); // ✅
        return {'success': true, 'data': model};
      }
      return {
        'success': false,
        'message': _extractMessage(response.data, 'Failed to load test'),
      };
    } on DioException catch (e) {
      return _errorPayload(e);
    } catch (e, stack) {
      // ✅ أضيفي هاد
      print('❌ getTestById parse error: $e');
      print('❌ stack: $stack');
      return {'success': false, 'message': e.toString()};
    }
  }

  // ✅ جديد: حذف الاختبار
  Future<Map<String, dynamic>> deleteTest(int testId) async {
    try {
      final response = await testService.deleteTest(testId);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        return {
          'success': true,
          'message': data['message'] ?? 'Test deleted successfully',
        };
      }
      final err = response.data;
      return {
        'success': false,
        'message': _extractMessage(err, 'Failed to delete test'),
      };
    } on DioException catch (e) {
      return _errorPayload(e);
    }
  }

  Future<Map<String, dynamic>> getAllTests() async {
    try {
      final response = await testService.getAllTests();
      if (response.statusCode == 200 || response.statusCode == 201) {
        final raw = response.data;
        final list = raw is List
            ? raw
            : (raw is Map && raw['data'] is List ? raw['data'] as List : []);

        final tests = list
            .whereType<Map>()
            .map((e) => TestModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();

        return {'success': true, 'data': tests};
      }
      return {
        'success': false,
        'message': _extractMessage(response.data, 'Failed to load tests'),
      };
    } on DioException catch (e) {
      return _errorPayload(e);
    }
  }

  List<TestModel> testsForLesson(List<TestModel> all, int lessonId) => all
      .where(
        (t) =>
            t.testableType.toLowerCase() == 'lesson' &&
            t.testableId == lessonId,
      )
      .toList();

  TestModel? courseTest(List<TestModel> all, int courseId) {
    final matches = all.where(
      (t) =>
          t.testableType.toLowerCase() == 'course' && t.testableId == courseId,
    );
    return matches.isEmpty ? null : matches.first;
  }
}
