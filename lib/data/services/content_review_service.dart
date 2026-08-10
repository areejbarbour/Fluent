import 'package:dio/dio.dart';
import 'package:fluent/constants/strings.dart';

/// Teacher Content Review APIs
/// Matches backend ContentReviewController exactly.
class ContentReviewService {
  final Dio dio;
  ContentReviewService(this.dio);

  Options get _opts => Options(
    headers: {'Accept': 'application/json'},
    validateStatus: (status) => status != null && status < 500,
  );

  /// POST /api/lessons/{lesson}/submit
  /// Response: { "lesson": ..., "test": ... }
  Future<Response> submitLesson(int lessonId) async {
    return await dio.post(apiSubmitLesson(lessonId), options: _opts);
  }

  /// POST /api/lessons/{lesson}/resubmit
  /// Response: { "lesson": ..., "review": ... }
  Future<Response> resubmitLesson(int lessonId) async {
    return await dio.post(apiResubmitLesson(lessonId), options: _opts);
  }

  /// POST /api/tests/{test}/submit
  /// Response: { "test": ... }
  Future<Response> submitTest(int testId) async {
    return await dio.post(apiSubmitTest(testId), options: _opts);
  }

  /// POST /api/tests/{test}/resubmit
  /// Response: { "test": ..., "review": ... }
  Future<Response> resubmitTest(int testId) async {
    return await dio.post(apiResubmitTest(testId), options: _opts);
  }

  /// GET /api/lessons/{lesson}/history
  /// Response: { "history": [ ... ] }
  Future<Response> lessonReviewHistory(int lessonId) async {
    return await dio.get(apiLessonReviewHistory(lessonId), options: _opts);
  }

  /// GET /api/tests/{test}/history
  /// Response: { "history": [ ... ] }
  Future<Response> testReviewHistory(int testId) async {
    return await dio.get(apiTestReviewHistory(testId), options: _opts);
  }
}
