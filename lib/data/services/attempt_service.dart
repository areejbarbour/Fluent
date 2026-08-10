import 'package:dio/dio.dart';
import 'package:fluent/constants/strings.dart';

/// Thin Dio layer — paths must match backend api.php student attempt routes.
class AttemptService {
  final Dio dio;
  AttemptService(this.dio);

  Options get _jsonOpts => Options(
    headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    // Let repository handle 4xx messages (validation, already taken, etc.)
    validateStatus: (s) => s != null && s < 500,
  );

  /// GET /api/startPlacementTest
  /// Picks latest published placement_test and starts an attempt.
  Future<Response> startPlacementTest() {
    return dio.get(apiStartPlacementTest, options: _jsonOpts);
  }

  /// POST /api/tests/{testId}/start
  Future<Response> startTest(int testId) {
    return dio.post(apiTestStart(testId), options: _jsonOpts);
  }

  /// POST /api/attempts/{attempt}/questions/{question}/submit-answer
  /// Body must include top-level key `answer` shaped per question type.
  Future<Response> submitAnswer({
    required int attemptId,
    required int questionId,
    required Map<String, dynamic> body,
  }) {
    return dio.post(
      apiAttemptSubmitAnswer(attemptId, questionId),
      data: body,
      options: _jsonOpts,
    );
  }

  /// POST /api/attempts/{attempt}/finish
  Future<Response> finish(int attemptId) {
    return dio.post(apiAttemptFinish(attemptId), options: _jsonOpts);
  }

  /// POST /api/attempts/{attempt}/leave  → status = abandoned
  Future<Response> leave(int attemptId) {
    return dio.post(apiAttemptLeave(attemptId), options: _jsonOpts);
  }

  /// GET /api/attempts/{attempt}/review
  /// Only available when attempt is completed AND passed.
  Future<Response> review(int attemptId) {
    return dio.get(apiAttemptReview(attemptId), options: _jsonOpts);
  }
}
