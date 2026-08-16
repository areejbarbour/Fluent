import 'package:dio/dio.dart';
import 'package:fluent/constants/strings.dart';

/// Thin Dio layer — matches backend ProgressController routes.
class ProgressService {
  final Dio dio;
  ProgressService(this.dio);

  Options get _opts => Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      );

  /// GET /api/courses/{course}/progress → { "progress": float }
  Future<Response> getCourseProgress(int courseId) {
    return dio.get(apiCourseProgress(courseId), options: _opts);
  }

  /// GET /api/levels/{level}/progress → { "progress": float }
  Future<Response> getLevelProgress(int levelId) {
    return dio.get(apiLevelProgress(levelId), options: _opts);
  }
}
