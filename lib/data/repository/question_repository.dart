import 'package:dio/dio.dart';
import 'package:fluent/data/models/question_model.dart';
import 'package:fluent/data/models/question_status_model.dart';
import 'package:fluent/data/services/question_service.dart';

class QuestionRepository {
  final QuestionService questionService;
  QuestionRepository(this.questionService);

  // ────────────────────────────────────────────
  // Pagination wrapper
  // ────────────────────────────────────────────
  PaginatedQuestions? _parsePaginated(Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        // find first list value (active_questions or deprecated_questions)
        Map<String, dynamic>? paginationMap;
        for (final entry in data.entries) {
          if (entry.value is Map<String, dynamic>) {
            paginationMap = entry.value as Map<String, dynamic>;
            break;
          }
        }
        if (paginationMap != null) {
          final list = paginationMap['data'];
          if (list is List) {
            final questions = list
                .whereType<Map>()
                .map((e) => Question.fromJson(Map<String, dynamic>.from(e)))
                .toList();

            // Laravel's ResourceCollection->response()->getData(true) nests
            // pagination info under "meta": { current_page, last_page, per_page, total }.
            // Fall back to paginationMap itself in case the backend shape changes.
            final meta = paginationMap['meta'] is Map<String, dynamic>
                ? paginationMap['meta'] as Map<String, dynamic>
                : paginationMap;

            return PaginatedQuestions(
              questions: questions,
              currentPage: meta['current_page'] is int
                  ? meta['current_page']
                  : 1,
              lastPage: meta['last_page'] is int ? meta['last_page'] : 1,
              perPage: meta['per_page'] is int ? meta['per_page'] : 10,
              total: meta['total'] is int ? meta['total'] : questions.length,
            );
          }
        }
      }
    }
    return null;
  }

  // Laravel wraps a single JsonResource returned directly from a controller
  // in a top-level "data" key by default (unless JsonResource::withoutWrapping()
  // is set). This helper works correctly whether or not that wrapping is enabled.
  Map<String, dynamic> _unwrapResource(Map<String, dynamic> raw) {
    final inner = raw['data'];
    if (inner is Map<String, dynamic> && (inner['id'] != null)) {
      return inner;
    }
    return raw;
  }

  // Laravel's default ValidationException response looks like:
  //   {"message": "The given data was invalid.", "errors": {"error": ["actual reason"]}}
  // The generic top-level "message" is useless for the user; the real,
  // meaningful text lives inside "errors". This pulls out the first
  // available error message, falling back to the generic one if needed.
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
    };
  }

  // ────────────────────────────────────────────
  // 1) GET /questions
  // ────────────────────────────────────────────
  Future<Map<String, dynamic>> getQuestions({int page = 1}) async {
    try {
      final response = await questionService.getQuestions(page: page);
      final paginated = _parsePaginated(response);
      if (paginated != null) {
        return {'success': true, 'data': paginated};
      }
      return {'success': false, 'message': 'Failed to load questions'};
    } on DioException catch (e) {
      return _errorPayload(e);
    }
  }

  // ────────────────────────────────────────────
  // 2) GET /questions/deprecated
  // ────────────────────────────────────────────
  Future<Map<String, dynamic>> getDeprecatedQuestions({int page = 1}) async {
    try {
      final response = await questionService.getDeprecatedQuestions(page: page);
      final paginated = _parsePaginated(response);
      if (paginated != null) {
        return {'success': true, 'data': paginated};
      }
      return {
        'success': false,
        'message': 'Failed to load deprecated questions',
      };
    } on DioException catch (e) {
      return _errorPayload(e);
    }
  }

  // ────────────────────────────────────────────
  // 3) GET /questions/{id}
  // ────────────────────────────────────────────
  Future<Map<String, dynamic>> getQuestion(int id) async {
    try {
      final response = await questionService.getQuestion(id);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return {
            'success': true,
            'data': Question.fromJson(_unwrapResource(data)),
          };
        }
      }
      final err = response.data;
      return {
        'success': false,
        'message': _extractMessage(err, 'Failed to load question'),
      };
    } on DioException catch (e) {
      return _errorPayload(e);
    }
  }

  // ────────────────────────────────────────────
  // 4) POST /questions
  // ────────────────────────────────────────────
  Future<Map<String, dynamic>> createQuestion(FormData formData) async {
    try {
      final response = await questionService.createQuestion(formData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return {
            'success': true,
            'data': Question.fromJson(_unwrapResource(data)),
          };
        }
      }
      final err = response.data;
      return {
        'success': false,
        'message': _extractMessage(err, 'Failed to create question'),
        'errors': err is Map ? err['errors'] : null,
      };
    } on DioException catch (e) {
      return _errorPayload(e);
    }
  }

  // ────────────────────────────────────────────
  // 5) POST /questions/{id}
  // ────────────────────────────────────────────
  Future<Map<String, dynamic>> updateQuestion(int id, FormData formData) async {
    try {
      final response = await questionService.updateQuestion(id, formData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          // response = {status, message, question: {...}}
          final questionJson = data['question'];
          Question? question;
          if (questionJson is Map<String, dynamic>) {
          question = Question.fromJson(_unwrapResource(questionJson));
          }
          return {
            'success': true,
            'status': data['status']?.toString() ?? 'updated',
            'message': data['message']?.toString() ?? 'Question updated',
            'data': question,
          };
        }
      }
      final err = response.data;
      return {
        'success': false,
        'message': _extractMessage(err, 'Failed to update question'),
        'errors': err is Map ? err['errors'] : null,
      };
    } on DioException catch (e) {
      return _errorPayload(e);
    }
  }

  // ────────────────────────────────────────────
  // 6) GET /questions/{id}/checkStatus
  //    Backend wraps in array: [ {...} ]
  // ────────────────────────────────────────────
  Future<Map<String, dynamic>> checkStatus(int id) async {
    try {
      final response = await questionService.checkStatus(id);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        Map<String, dynamic>? statusMap;
        if (data is List && data.isNotEmpty && data.first is Map) {
          statusMap = Map<String, dynamic>.from(data.first as Map);
        } else if (data is Map<String, dynamic>) {
          statusMap = data;
        }
        if (statusMap != null) {
          return {'success': true, 'data': QuestionStatus.fromJson(statusMap)};
        }
      }
      return {'success': false, 'message': 'Failed to load question status'};
    } on DioException catch (e) {
      return _errorPayload(e);
    }
  }

  // ────────────────────────────────────────────
  // 7) GET /questions/{id}/delete
  //    Backend returns true/false
  // ────────────────────────────────────────────
  Future<Map<String, dynamic>> deleteQuestion(int id) async {
    try {
      final response = await questionService.deleteQuestion(id);
      if (response.statusCode == 200 || response.statusCode == 201) {
        // success
        return {'success': true, 'message': 'Question deleted successfully'};
      }
      final err = response.data;
      return {
        'success': false,
        'message': _extractMessage(err, 'Failed to delete question'),
        'errors': err is Map ? err['errors'] : null,
      };
    } on DioException catch (e) {
      return _errorPayload(e);
    }
  }

  // ────────────────────────────────────────────
  // 8) GET /questions/{id}/blocking-tests
  // ────────────────────────────────────────────
  Future<Map<String, dynamic>> blockingTests(int id) async {
    try {
      final response = await questionService.blockingTests(id);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return {'success': true, 'data': BlockingTests.fromJson(data)};
        }
      }
      return {'success': false, 'message': 'Failed to load blocking tests'};
    } on DioException catch (e) {
      return _errorPayload(e);
    }
  }
}

class PaginatedQuestions {
  final List<Question> questions;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  PaginatedQuestions({
    required this.questions,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;
}
