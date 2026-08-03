import 'package:dio/dio.dart';
import 'package:fluent/constants/strings.dart';

/// Backend (student only, auth:sanctum + role:student):
/// - POST   /api/rate/{course}          body: { "stars": 1..5 }
/// - DELETE /api/rate/{rate}/delete
///
/// Rules (RateServiece):
/// - Course must be completed by the student (pivot status = completed)
/// - updateOrCreate on (course_id, user_id)
/// - Delete only if rate.user_id === auth id
class RateService {
  final Dio dio;
  RateService(this.dio);

  Future<Response> rateCourse(int courseId, int stars) async {
    return await dio.post(
      apiRateCourse(courseId),
      data: {'stars': stars},
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  Future<Response> deleteRate(int rateId) async {
    return await dio.delete(
      apiDeleteRate(rateId),
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }
}
