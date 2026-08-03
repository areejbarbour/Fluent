import 'package:dio/dio.dart';
import 'package:fluent/helper/api_error_helper.dart';
import 'package:fluent/data/models/rate_model.dart';
import 'package:fluent/data/services/rate_service.dart';

class RateRepository {
  final RateService rateService;
  RateRepository(this.rateService);

  /// Backend StoreRateRequest: stars nullable|integer|min:1|max:5
  /// We enforce 1..5 on the client before calling the API.
  static const int minStars = 1;
  static const int maxStars = 5;

  String _extractMessage(dynamic data, String fallback) {
    return ApiErrorHelper.extract(
      data,
      fallback,
      preferredKeys: const ['course', 'stars', 'rate', 'message'],
    );
  }

  Map<String, dynamic>? _unwrapResource(dynamic data) {
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);
    if (map['data'] is Map) {
      return Map<String, dynamic>.from(map['data'] as Map);
    }
    if (map.containsKey('id') && map.containsKey('stars')) {
      return map;
    }
    return null;
  }

  Map<String, dynamic> _errorPayload(dynamic data, String fallback) {
    return {
      'success': false,
      'message': _extractMessage(data, fallback),
      'errors': data is Map ? data['errors'] : null,
    };
  }

  /// POST /api/rate/{course}
  /// Success → RateResource { id, stars }
  Future<Map<String, dynamic>> rateCourse({
    required int courseId,
    required int stars,
  }) async {
    if (stars < minStars || stars > maxStars) {
      return {
        'success': false,
        'message': 'Stars must be between $minStars and $maxStars.',
        'errors': {
          'stars': ['Stars must be between $minStars and $maxStars.'],
        },
      };
    }

    try {
      final response = await rateService.rateCourse(courseId, stars);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final unwrapped = _unwrapResource(response.data);
        if (unwrapped != null) {
          final model = RateModel.fromJson(unwrapped);
          return {'success': true, 'data': model};
        }
        return {'success': false, 'message': 'Unexpected response format'};
      }

      return _errorPayload(response.data, 'Failed to rate course');
    } on DioException catch (e) {
      return _errorPayload(e.response?.data, e.message ?? 'Request failed');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// DELETE /api/rate/{rate}/delete
  /// Success → { "rate deleted successfully" } (array/string from service)
  Future<Map<String, dynamic>> deleteRate(int rateId) async {
    if (rateId <= 0) {
      return {'success': false, 'message': 'Invalid rate id.'};
    }

    try {
      final response = await rateService.deleteRate(rateId);

      if (response.statusCode == 200 || response.statusCode == 201) {
        String message = 'rate deleted successfully';
        final data = response.data;
        if (data is Map && data['message'] is String) {
          message = data['message'] as String;
        } else if (data is List && data.isNotEmpty) {
          message = data.first.toString();
        } else if (data is String && data.isNotEmpty) {
          message = data;
        }
        return {'success': true, 'message': message};
      }

      return _errorPayload(response.data, 'Failed to delete rating');
    } on DioException catch (e) {
      return _errorPayload(e.response?.data, e.message ?? 'Request failed');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
