import 'package:dio/dio.dart';
import 'package:fluent/data/models/attempt_models.dart';
import 'package:fluent/data/services/attempt_service.dart';
import 'package:fluent/helper/questions/answer_payload_helper.dart';

class AttemptRepository {
  final AttemptService attemptService;
  AttemptRepository(this.attemptService);

  String _extractMessage(dynamic data, String fallback) {
    if (data is! Map) return fallback;

    final errors = data['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
      if (first is String) return first;
    }

    if (data['message'] is String && (data['message'] as String).isNotEmpty) {
      return data['message'] as String;
    }
    if (data['error'] is String) return data['error'] as String;
    return fallback;
  }

  Map<String, dynamic> _fail(
    dynamic data,
    String fallback, {
    bool isPlacementBlocked = false,
  }) {
    return {
      'success': false,
      'message': _extractMessage(data, fallback),
      'errors': data is Map ? data['errors'] : null,
      'isPlacementBlocked': isPlacementBlocked,
    };
  }

  bool _ok(int? code) => code == 200 || code == 201;

  bool _looksLikePlacementBlock(dynamic data, String msg) {
    final raw = '${data ?? ''} $msg'.toLowerCase();
    return raw.contains('diffindays') ||
        raw.contains('iseligibleforplacementretake') ||
        raw.contains('already taken') ||
        raw.contains('placement test') ||
        raw.contains('cooldown');
  }

  Future<Map<String, dynamic>> startPlacementTest() async {
    try {
      final res = await attemptService.startPlacementTest();
      if (_ok(res.statusCode) && res.data is Map) {
        final result = AttemptStartResult.fromJson(
          Map<String, dynamic>.from(res.data as Map),
        );
        if (result.attemptId <= 0) {
          return {
            'success': false,
            'message': 'Invalid attempt_id from server',
          };
        }
        return {'success': true, 'data': result};
      }
      return _fail(res.data, 'Failed to start placement test');
    } on DioException catch (e) {
      final data = e.response?.data;
      final status = e.response?.statusCode;
      var msg = _extractMessage(
        data,
        e.message ?? 'Failed to start placement test',
      );

      // Backend may 500 on completed_at string (diffInDays) — treat as blocked.
      final blocked =
          status == 422 || status == 500 || _looksLikePlacementBlock(data, msg);

      if (status == 500 && _looksLikePlacementBlock(data, msg)) {
        msg =
            'You already completed a placement test. '
            'Retake is not available until the cooldown ends '
            '(or a level is assigned).';
      } else if (status == 500) {
        msg = 'Server error while starting placement. Please try again later.';
      }

      return {
        'success': false,
        'message': msg,
        'errors': data is Map ? data['errors'] : null,
        'isPlacementBlocked': blocked,
      };
    }
  }

  Future<Map<String, dynamic>> startTest(int testId) async {
    try {
      final res = await attemptService.startTest(testId);
      if (_ok(res.statusCode) && res.data is Map) {
        final result = AttemptStartResult.fromJson(
          Map<String, dynamic>.from(res.data as Map),
        );
        return {'success': true, 'data': result};
      }
      return _fail(res.data, 'Failed to start test');
    } on DioException catch (e) {
      return _fail(e.response?.data, e.message ?? 'Failed to start test');
    }
  }

  Future<Map<String, dynamic>> submitAnswer({
    required int attemptId,
    required int questionId,
    required Map<String, dynamic> body,
  }) async {
    try {
      final res = await attemptService.submitAnswer(
        attemptId: attemptId,
        questionId: questionId,
        body: body,
      );
      if (_ok(res.statusCode)) {
        return {
          'success': true,
          'data': SubmitAnswerResult.fromResponse(res.data),
        };
      }
      return _fail(res.data, 'Failed to submit answer');
    } on DioException catch (e) {
      return _fail(e.response?.data, e.message ?? 'Failed to submit answer');
    }
  }

  Future<Map<String, dynamic>> submitMcq({
    required int attemptId,
    required int questionId,
    required int selectedAnswerId,
  }) {
    return submitAnswer(
      attemptId: attemptId,
      questionId: questionId,
      body: AnswerPayloadHelper.mcq(selectedAnswerId: selectedAnswerId),
    );
  }

  Future<Map<String, dynamic>> submitFill({
    required int attemptId,
    required int questionId,
    required Map<int, String> blankInputs,
  }) {
    return submitAnswer(
      attemptId: attemptId,
      questionId: questionId,
      body: AnswerPayloadHelper.fill(blankInputs: blankInputs),
    );
  }

  Future<Map<String, dynamic>> submitArrange({
    required int attemptId,
    required int questionId,
    required List<int> orderedIds,
  }) {
    return submitAnswer(
      attemptId: attemptId,
      questionId: questionId,
      body: AnswerPayloadHelper.arrange(orderedIds: orderedIds),
    );
  }

  Future<Map<String, dynamic>> submitPair({
    required int attemptId,
    required int questionId,
    required Map<int, int> matches,
  }) {
    return submitAnswer(
      attemptId: attemptId,
      questionId: questionId,
      body: AnswerPayloadHelper.pair(matches: matches),
    );
  }

  Future<Map<String, dynamic>> finish(int attemptId) async {
    try {
      final res = await attemptService.finish(attemptId);
      if (_ok(res.statusCode) && res.data is Map) {
        return {
          'success': true,
          'data': FinishAttemptResult.fromJson(
            Map<String, dynamic>.from(res.data as Map),
          ),
        };
      }
      return _fail(res.data, 'Failed to finish attempt');
    } on DioException catch (e) {
      return _fail(e.response?.data, e.message ?? 'Failed to finish attempt');
    }
  }

  Future<Map<String, dynamic>> leave(int attemptId) async {
    try {
      final res = await attemptService.leave(attemptId);
      if (_ok(res.statusCode)) {
        return {'success': true, 'data': res.data};
      }
      return _fail(res.data, 'Failed to leave attempt');
    } on DioException catch (e) {
      return _fail(e.response?.data, e.message ?? 'Failed to leave attempt');
    }
  }

  Future<Map<String, dynamic>> review(int attemptId) async {
    try {
      final res = await attemptService.review(attemptId);
      if (_ok(res.statusCode) && res.data is Map) {
        return {
          'success': true,
          'data': ReviewAttemptResult.fromJson(
            Map<String, dynamic>.from(res.data as Map),
          ),
        };
      }
      return _fail(res.data, 'Failed to load review');
    } on DioException catch (e) {
      return _fail(e.response?.data, e.message ?? 'Failed to load review');
    }
  }
}
