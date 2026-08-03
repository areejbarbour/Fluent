import 'package:dio/dio.dart';

/// Shared Laravel / Dio error extraction — same approach as teacher repositories.
///
/// Priority:
/// 1) first entry in `errors` map (field validation)
/// 2) top-level `message`
/// 3) top-level `error`
/// 4) fallback
class ApiErrorHelper {
  ApiErrorHelper._();

  /// Prefer specific field keys when present (e.g. comment, stars, word).
  static String extract(
    dynamic data,
    String fallback, {
    List<String> preferredKeys = const [],
  }) {
    if (data is! Map) return fallback;
    final errors = data['errors'];
    if (errors is Map && errors.isNotEmpty) {
      for (final key in preferredKeys) {
        final v = errors[key];
        if (v is List && v.isNotEmpty) return v.first.toString();
        if (v is String && v.isNotEmpty) return v;
      }
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
      if (first is String && first.isNotEmpty) return first;
    }
    if (data['message'] is String &&
        (data['message'] as String).trim().isNotEmpty) {
      return (data['message'] as String).trim();
    }
    if (data['error'] is String &&
        (data['error'] as String).trim().isNotEmpty) {
      return (data['error'] as String).trim();
    }
    return fallback;
  }

  static Map<String, dynamic> failure(
    dynamic data,
    String fallback, {
    List<String> preferredKeys = const [],
  }) {
    return {
      'success': false,
      'message': extract(data, fallback, preferredKeys: preferredKeys),
      'errors': data is Map ? data['errors'] : null,
    };
  }

  static Map<String, dynamic> fromDio(
    DioException e,
    String fallback, {
    List<String> preferredKeys = const [],
  }) {
    // Network / timeout — no Laravel body
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return {
        'success': false,
        'message': 'Connection timed out. Please try again.',
        'errors': null,
      };
    }
    if (e.type == DioExceptionType.connectionError) {
      return {
        'success': false,
        'message': 'No internet connection. Please check your network.',
        'errors': null,
      };
    }
    return failure(
      e.response?.data,
      e.message ?? fallback,
      preferredKeys: preferredKeys,
    );
  }
}
