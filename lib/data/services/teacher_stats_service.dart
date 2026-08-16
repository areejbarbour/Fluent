import 'package:dio/dio.dart';
import 'package:fluent/constants/strings.dart';

/// Teacher Stats APIs — matches backend TeacherStatsController exactly.
///
/// GET /api/courses/{course}/stats
/// GET /api/tests/{test}/stats
class TeacherStatsService {
  final Dio dio;
  TeacherStatsService(this.dio);

  Options get _opts => Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      );

  /// GET /api/courses/{course}/stats
  /// Response body is the stats object directly (not wrapped in "data").
  Future<Response> getCourseStats(int courseId) async {
    return await dio.get(
      apiCourseStats(courseId),
      options: _opts,
    );
  }

  /// GET /api/tests/{test}/stats
  Future<Response> getTestStats(int testId) async {
    return await dio.get(
      apiTestStats(testId),
      options: _opts,
    );
  }
}
