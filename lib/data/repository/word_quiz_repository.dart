import 'package:dio/dio.dart';
import 'package:fluent/helper/api_error_helper.dart';
import 'package:fluent/data/models/word_quiz_model.dart';
import 'package:fluent/data/services/word_quiz_service.dart';

class WordQuizRepository {
  final WordQuizService service;
  WordQuizRepository(this.service);

  String _extractMessage(dynamic data, String fallback) {
    return ApiErrorHelper.extract(
      data,
      fallback,
      preferredKeys: const ['answer_id', 'word', 'message'],
    );
  }

  /// GET /api/words/quiz
  /// Backend may return a bare List or { data: [...] }
  Future<Map<String, dynamic>> getQuiz() async {
    try {
      final response = await service.getQuiz();
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        List list = const [];
        if (data is List) {
          list = data;
        } else if (data is Map) {
          if (data['data'] is List) {
            list = data['data'] as List;
          } else if (data['Quiz'] != null) {
            list = [data];
          }
        }

        final questions = list
            .whereType<Map>()
            .map((e) => WordQuizQuestion.fromJson(Map<String, dynamic>.from(e)))
            .where((q) => q.wordId > 0 && q.options.isNotEmpty)
            .toList();

        return {'success': true, 'data': questions};
      }
      return {
        'success': false,
        'message': _extractMessage(response.data, 'Failed to load quiz'),
      };
    } on DioException catch (e) {
      return ApiErrorHelper.fromDio(
        e,
        'Request failed',
        preferredKeys: const ['answer_id', 'word', 'message'],
      );
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// POST /api/words/{word}/quiz_check  { answer_id }
  Future<Map<String, dynamic>> checkAnswer({
    required int wordId,
    required int answerId,
  }) async {
    if (wordId <= 0 || answerId <= 0) {
      return {'success': false, 'message': 'Invalid word or answer.'};
    }

    try {
      final response = await service.checkAnswer(
        wordId: wordId,
        answerId: answerId,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        Map<String, dynamic>? map;
        if (data is Map) {
          if (data['data'] is Map) {
            map = Map<String, dynamic>.from(data['data'] as Map);
          } else {
            map = Map<String, dynamic>.from(data);
          }
        }
        if (map != null && map.containsKey('correct')) {
          return {'success': true, 'data': WordQuizCheckResult.fromJson(map)};
        }
        return {'success': false, 'message': 'Unexpected response format'};
      }

      return {
        'success': false,
        'message': _extractMessage(response.data, 'Failed to check answer'),
      };
    } on DioException catch (e) {
      return ApiErrorHelper.fromDio(
        e,
        'Request failed',
        preferredKeys: const ['answer_id', 'word', 'message'],
      );
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
