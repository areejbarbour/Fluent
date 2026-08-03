import 'package:dio/dio.dart';
import 'package:fluent/data/models/test_model.dart';
import 'package:fluent/data/services/test_service.dart';

class TestRepository {
  final TestService testService;
  TestRepository(this.testService);

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic> && data['data'] is List) {
      return data['data'] as List;
    }
    return const [];
  }

  String _extractMessage(dynamic data, String fallback) {
    if (data is! Map) return fallback;

    final errors = data['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final firstValue = errors.values.first;
      if (firstValue is List && firstValue.isNotEmpty) {
        return firstValue.first.toString();
      }
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

  List<TestModel> _parseTests(dynamic data) {
    final list = _extractList(data);

    return list
        .whereType<Map>()
        .map((e) => TestModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Map<String, dynamic>> getTeacherTests() async {
    try {
      final response = await testService.getTeacherTests();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final tests = _parseTests(response.data);
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

  Future<Map<String, dynamic>> getAllTests() async {
    try {
      final response = await testService.getAllTests();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final tests = _parseTests(response.data);
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

  Future<Map<String, dynamic>> getTestById(int testId) async {
    try {
      final response = await testService.getTestById(testId);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final raw = data is Map<String, dynamic>
            ? (data['data'] ?? data)
            : data;
        final model = TestModel.fromJson(Map<String, dynamic>.from(raw));

        return {'success': true, 'data': model};
      }

      return {
        'success': false,
        'message': _extractMessage(response.data, 'Failed to load test'),
      };
    } on DioException catch (e) {
      return _errorPayload(e);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createTest(Map<String, dynamic> payload) async {
    try {
      final response = await testService.createTest(payload);

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

  Future<Map<String, dynamic>> updateTest(
    int testId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await testService.updateTest(testId, payload);

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

  Future<Map<String, dynamic>> deleteTest(int testId) async {
    try {
      final response = await testService.deleteTest(testId);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        return {
          'success': true,
          'message': data is Map
              ? (data['message'] ?? 'Test deleted successfully')
              : 'Test deleted successfully',
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

  List<TestModel> testsForLesson(List<TestModel> all, int lessonId) {
    return all
        .where(
          (t) =>
              t.normalizedTestableType == 'lesson' && t.testableId == lessonId,
        )
        .toList();
  }

  List<TestModel> testsForCourse(List<TestModel> all, int courseId) {
    return all
        .where(
          (t) =>
              t.normalizedTestableType == 'course' && t.testableId == courseId,
        )
        .toList();
  }
}
