import 'package:dio/dio.dart';
import 'package:fluent/data/models/teacher_stats_model.dart';
import 'package:fluent/data/services/teacher_stats_service.dart';

class TeacherStatsRepository {
  final TeacherStatsService service;
  TeacherStatsRepository(this.service);

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
    if (data['message'] is String && (data['message'] as String).isNotEmpty) {
      return data['message'] as String;
    }
    if (data['error'] is String && (data['error'] as String).isNotEmpty) {
      return data['error'] as String;
    }
    return fallback;
  }

  Map<String, dynamic> _errorPayload(DioException e) {
    final data = e.response?.data;
    return {
      'success': false,
      'message': _extractMessage(data, e.message ?? 'Request failed'),
      'errors': data is Map ? data['errors'] : null,
      'statusCode': e.response?.statusCode,
    };
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  /// GET /api/courses/{course}/stats
  /// Backend returns the JSON object directly (authorize update on course).
  Future<Map<String, dynamic>> getCourseStats(int courseId) async {
    try {
      final response = await service.getCourseStats(courseId);
      final data = response.data;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final map = _asMap(data);
        if (map != null) {
          return {
            'success': true,
            'data': CourseStats.fromJson(map),
          };
        }
      }

      if (response.statusCode == 403) {
        return {
          'success': false,
          'message': 'You are not allowed to view stats for this course.',
          'statusCode': 403,
        };
      }

      return {
        'success': false,
        'message': _extractMessage(data, 'Failed to load course statistics'),
        'errors': data is Map ? data['errors'] : null,
        'statusCode': response.statusCode,
      };
    } on DioException catch (e) {
      return _errorPayload(e);
    }
  }

  /// GET /api/tests/{test}/stats
  Future<Map<String, dynamic>> getTestStats(int testId) async {
    try {
      final response = await service.getTestStats(testId);
      final data = response.data;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final map = _asMap(data);
        if (map != null) {
          return {
            'success': true,
            'data': TestStats.fromJson(map),
          };
        }
      }

      if (response.statusCode == 403) {
        return {
          'success': false,
          'message': 'You are not allowed to view stats for this test.',
          'statusCode': 403,
        };
      }

      return {
        'success': false,
        'message': _extractMessage(data, 'Failed to load test statistics'),
        'errors': data is Map ? data['errors'] : null,
        'statusCode': response.statusCode,
      };
    } on DioException catch (e) {
      return _errorPayload(e);
    }
  }
}
