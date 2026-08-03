import 'package:dio/dio.dart';
import 'package:fluent/data/models/lesson_word_model.dart';
import 'package:fluent/data/services/lesson_word_service.dart';
import 'package:fluent/helper/api_error_helper.dart';

class LessonWordRepository {
  final LessonWordService service;
  LessonWordRepository(this.service);

  static const _wordKeys = ['word', 'lesson', 'message'];

  Future<Map<String, dynamic>> getLessonWords(int lessonId) async {
    try {
      final response = await service.getLessonWords(lessonId);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        List<LessonWordModel> list = [];
        if (data is Map && data['data'] is List) {
          list = (data['data'] as List)
              .whereType<Map>()
              .map(
                (e) => LessonWordModel.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList();
        } else if (data is List) {
          list = data
              .whereType<Map>()
              .map(
                (e) => LessonWordModel.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList();
        }
        return {'success': true, 'data': list};
      }
      return ApiErrorHelper.failure(
        response.data,
        'Failed to load lesson words',
        preferredKeys: _wordKeys,
      );
    } on DioException catch (e) {
      return ApiErrorHelper.fromDio(
        e,
        'Failed to load lesson words',
        preferredKeys: _wordKeys,
      );
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  Future<Map<String, dynamic>> moveToLearning(int wordId) async {
    try {
      final response = await service.moveToLearning(wordId);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': ApiErrorHelper.extract(
            response.data,
            'Word added to learning list',
          ),
          'data': response.data,
        };
      }
      return ApiErrorHelper.failure(
        response.data,
        'Failed to update word status',
        preferredKeys: _wordKeys,
      );
    } on DioException catch (e) {
      return ApiErrorHelper.fromDio(
        e,
        'Failed to update word status',
        preferredKeys: _wordKeys,
      );
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  Future<Map<String, dynamic>> moveToKnow(int wordId) async {
    try {
      final response = await service.moveToKnow(wordId);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': ApiErrorHelper.extract(
            response.data,
            'Word added to known words',
          ),
          'data': response.data,
        };
      }
      return ApiErrorHelper.failure(
        response.data,
        'Failed to update word status',
        preferredKeys: _wordKeys,
      );
    } on DioException catch (e) {
      return ApiErrorHelper.fromDio(
        e,
        'Failed to update word status',
        preferredKeys: _wordKeys,
      );
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }
}
