

import 'package:dio/dio.dart';
import '../models/lesson_detail_model.dart';
import 'package:fluent/data/services/lesson_detail_service.dart';

class LessonDetailRepository {
  final LessonDetailService lessonDetailService;
  LessonDetailRepository(this.lessonDetailService);

  Future<Map<String, dynamic>> getLessonDetail(int lessonId) async {
    try {
      final response = await lessonDetailService.getLessonDetail(lessonId);
      print("✅ GetLessonDetail Status: ${response.statusCode}");
      print("✅ GetLessonDetail Data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return {'success': true, 'data': LessonDetailModel.fromJson(data)};
        }
        return {'success': false, 'message': 'صيغة استجابة غير متوقعة'};
      } else {
        final errorData = response.data;
        return {
          'success': false,
          'message': errorData is Map
              ? errorData['message'] ?? 'فشل في جلب تفاصيل الدرس'
              : 'فشل في جلب تفاصيل الدرس',
        };
      }
    } on DioException catch (e) {
      print("❌ GetLessonDetail DioException: ${e.response?.data}");
      final errorData = e.response?.data;
      return {
        'success': false,
        'message': errorData is Map
            ? errorData['message'] ?? 'حدث خطأ ما'
            : e.message ?? 'حدث خطأ ما',
      };
    } catch (e) {
      print("❌ GetLessonDetail Unexpected error: $e");
      return {'success': false, 'message': 'حدث خطأ غير متوقع'};
    }
  }

  Future<Map<String, dynamic>> postComment(int lessonId, String comment) async {
    try {
      final response = await lessonDetailService.postComment(lessonId, comment);
      print("✅ PostComment Status: ${response.statusCode}");
      print("✅ PostComment Data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['data'] is Map) {
          return {
            'success': true,
            'data': LessonCommentModel.fromJson(
                Map<String, dynamic>.from(data['data'])),
          };
        }
        return {'success': false, 'message': 'صيغة استجابة غير متوقعة'};
      } else {
        final errorData = response.data;
        return {
          'success': false,
          'message': errorData is Map
              ? errorData['message'] ?? 'فشل في إضافة التعليق'
              : 'فشل في إضافة التعليق',
        };
      }
    } on DioException catch (e) {
      print("❌ PostComment DioException: ${e.response?.data}");
      final errorData = e.response?.data;
      return {
        'success': false,
        'message': errorData is Map
            ? errorData['message'] ?? 'حدث خطأ ما'
            : e.message ?? 'حدث خطأ ما',
      };
    } catch (e) {
      print("❌ PostComment Unexpected error: $e");
      return {'success': false, 'message': 'حدث خطأ غير متوقع'};
    }
  }

  Future<Map<String, dynamic>> updateComment(
      int commentId, String comment) async {
    try {
      final response =
          await lessonDetailService.updateComment(commentId, comment);
      print("✅ UpdateComment Status: ${response.statusCode}");
      print("✅ UpdateComment Data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['data'] is Map) {
          return {
            'success': true,
            'data': LessonCommentModel.fromJson(
                Map<String, dynamic>.from(data['data'])),
          };
        }
        return {'success': false, 'message': 'صيغة استجابة غير متوقعة'};
      } else {
        final errorData = response.data;
        return {
          'success': false,
          'message': errorData is Map
              ? errorData['message'] ?? 'فشل في تعديل التعليق'
              : 'فشل في تعديل التعليق',
        };
      }
    } on DioException catch (e) {
      print("❌ UpdateComment DioException: ${e.response?.data}");
      final errorData = e.response?.data;
      return {
        'success': false,
        'message': errorData is Map
            ? errorData['message'] ?? 'حدث خطأ ما'
            : e.message ?? 'حدث خطأ ما',
      };
    } catch (e) {
      print("❌ UpdateComment Unexpected error: $e");
      return {'success': false, 'message': 'حدث خطأ غير متوقع'};
    }
  }

  Future<Map<String, dynamic>> deleteComment(int commentId) async {
    try {
      final response = await lessonDetailService.deleteComment(commentId);
      print("✅ DeleteComment Status: ${response.statusCode}");
      print("✅ DeleteComment Data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true};
      } else {
        final errorData = response.data;
        return {
          'success': false,
          'message': errorData is Map
              ? errorData['message'] ?? 'فشل في حذف التعليق'
              : 'فشل في حذف التعليق',
        };
      }
    } on DioException catch (e) {
      print("❌ DeleteComment DioException: ${e.response?.data}");
      final errorData = e.response?.data;
      return {
        'success': false,
        'message': errorData is Map
            ? errorData['message'] ?? 'حدث خطأ ما'
            : e.message ?? 'حدث خطأ ما',
      };
    } catch (e) {
      print("❌ DeleteComment Unexpected error: $e");
      return {'success': false, 'message': 'حدث خطأ غير متوقع'};
    }
  }
}