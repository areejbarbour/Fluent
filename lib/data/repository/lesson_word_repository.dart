import 'package:dio/dio.dart';
import 'package:fluent/data/models/lesson_word_model.dart';
import 'package:fluent/data/services/lesson_word_service.dart';

class LessonWordRepository {
  final LessonWordService service;
  LessonWordRepository(this.service);

  Future<Map<String, dynamic>> getLessonWords(int lessonId) async {
    try {
      final response = await service.getLessonWords(lessonId);
      print("✅ GetLessonWords Status: ${response.statusCode}");
      print("✅ GetLessonWords Data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        List<LessonWordModel> list = [];

        if (data is Map && data['data'] is List) {
          list = (data['data'] as List)
              .whereType<Map>()
              .map((e) =>
                  LessonWordModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        } else if (data is List) {
          list = data
              .whereType<Map>()
              .map((e) =>
                  LessonWordModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }

        return {'success': true, 'data': list};
      }

      final errorData = response.data;
      return {
        'success': false,
        'message': errorData is Map
            ? errorData['message'] ?? 'فشل في جلب كلمات الدرس'
            : 'فشل في جلب كلمات الدرس',
      };
    } on DioException catch (e) {
      print("❌ GetLessonWords DioException: ${e.response?.data}");
      final errorData = e.response?.data;
      return {
        'success': false,
        'message': errorData is Map
            ? errorData['message'] ?? 'حدث خطأ ما'
            : e.message ?? 'حدث خطأ ما',
      };
    } catch (e) {
      print("❌ GetLessonWords Unexpected error: $e");
      return {'success': false, 'message': 'حدث خطأ غير متوقع'};
    }
  }

  Future<Map<String, dynamic>> moveToLearning(int wordId) async {
  try {
    final response = await service.moveToLearning(wordId);
    print("✅ MoveToLearning Status: ${response.statusCode}");
    print("✅ MoveToLearning Data: ${response.data}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {
        'success': true,
        'message': 'تم نقل الكلمة إلى قائمة التعلم',
      };
    }

    final errorData = response.data;
    return {
      'success': false,
      'message': errorData is Map
          ? errorData['message'] ?? 'فشل النقل'
          : 'فشل النقل',
    };
  } on DioException catch (e) {
    print("❌ MoveToLearning DioException: ${e.response?.data}");
    final errorData = e.response?.data;
    return {
      'success': false,
      'message': errorData is Map
          ? errorData['message'] ?? 'حدث خطأ ما'
          : e.message ?? 'حدث خطأ ما',
    };
  } catch (e) {
    return {'success': false, 'message': 'حدث خطأ غير متوقع'};
  }
}

Future<Map<String, dynamic>> moveToKnow(int wordId) async {
  try {
    final response = await service.moveToKnow(wordId);
    print("✅ MoveToKnow Status: ${response.statusCode}");
    print("✅ MoveToKnow Data: ${response.data}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {
        'success': true,
        'message': 'تم نقل الكلمة إلى قائمة المعروف',
      };
    }

    final errorData = response.data;
    return {
      'success': false,
      'message': errorData is Map
          ? errorData['message'] ?? 'فشل النقل'
          : 'فشل النقل',
    };
  } on DioException catch (e) {
    print("❌ MoveToKnow DioException: ${e.response?.data}");
    final errorData = e.response?.data;
    return {
      'success': false,
      'message': errorData is Map
          ? errorData['message'] ?? 'حدث خطأ ما'
          : e.message ?? 'حدث خطأ ما',
    };
  } catch (e) {
    return {'success': false, 'message': 'حدث خطأ غير متوقع'};
  }
}
}