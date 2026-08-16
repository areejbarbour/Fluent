import 'package:dio/dio.dart';
import 'package:fluent/data/services/progress_service.dart';
import 'package:fluent/helper/api_error_helper.dart';

class ProgressRepository {
  final ProgressService progressService;
  ProgressRepository(this.progressService);

  Future<Map<String, dynamic>> getCourseProgress(int courseId) async {
    try {
      final res = await progressService.getCourseProgress(courseId);
      if ((res.statusCode == 200 || res.statusCode == 201) && res.data is Map) {
        final raw = (res.data as Map)['progress'];
        final value = raw is num
            ? raw.toDouble()
            : double.tryParse(raw?.toString() ?? '') ?? 0.0;
        return {'success': true, 'data': value};
      }
      return ApiErrorHelper.failure(res.data, 'Failed to load course progress');
    } on DioException catch (e) {
      return ApiErrorHelper.fromDio(e, 'Failed to load course progress');
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  Future<Map<String, dynamic>> getLevelProgress(int levelId) async {
    try {
      final res = await progressService.getLevelProgress(levelId);
      if ((res.statusCode == 200 || res.statusCode == 201) && res.data is Map) {
        final raw = (res.data as Map)['progress'];
        final value = raw is num
            ? raw.toDouble()
            : double.tryParse(raw?.toString() ?? '') ?? 0.0;
        return {'success': true, 'data': value};
      }
      return ApiErrorHelper.failure(res.data, 'Failed to load level progress');
    } on DioException catch (e) {
      return ApiErrorHelper.fromDio(e, 'Failed to load level progress');
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }
}
