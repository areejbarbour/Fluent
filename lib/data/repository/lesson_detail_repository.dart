import 'package:dio/dio.dart';
import '../models/lesson_detail_model.dart';
import 'package:fluent/data/services/lesson_detail_service.dart';

class LessonDetailRepository {
  final LessonDetailService lessonDetailService;
  LessonDetailRepository(this.lessonDetailService);

  /// يستخرج رسالة خطأ واضحة من استجابة Laravel (message أو errors.comment)
  static String extractErrorMessage(dynamic errorData, String fallback) {
    if (errorData is! Map) return fallback;
    final map = Map<String, dynamic>.from(errorData);

    final errors = map['errors'];
    if (errors is Map) {
      final commentErr = errors['comment'];
      if (commentErr is List && commentErr.isNotEmpty) {
        return commentErr.first.toString();
      }
      if (commentErr != null) return commentErr.toString();
      // أول خطأ متاح
      for (final v in errors.values) {
        if (v is List && v.isNotEmpty) return v.first.toString();
        if (v != null) return v.toString();
      }
    }

    final msg = map['message'];
    if (msg is String && msg.isNotEmpty) return msg;
    if (msg is List && msg.isNotEmpty) return msg.first.toString();

    return fallback;
  }

  /// يفكّ CommentResource سواء كان { data: {...} } أو الكائن مباشرة
  static Map<String, dynamic>? unwrapResource(dynamic data) {
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);
    if (map['data'] is Map) {
      return Map<String, dynamic>.from(map['data'] as Map);
    }
    // بعض الـ APIs ترجع الحقول مباشرة
    if (map.containsKey('id') && map.containsKey('comment')) {
      return map;
    }
    return null;
  }

  Future<Map<String, dynamic>> getLessonDetail(
    int lessonId, {
    int page = 1,
    int? currentUserId,
    bool teacher = false,
  }) async {
    try {
      final response = await lessonDetailService.getLessonDetail(
        lessonId,
        page: page,
        teacher: teacher,
      );
      print("✅ GetLessonDetail Status: ${response.statusCode}");
      print("✅ GetLessonDetail Data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final model = LessonDetailModel.fromJson(
            data,
            currentUserId: currentUserId,
            requestedPage: page,
          );
          return {
            'success': true,
            'data': model,
            'rawLesson': data['lesson'],
            'raw': data,
          };
        }
        if (data is Map) {
          final map = Map<String, dynamic>.from(data);
          final model = LessonDetailModel.fromJson(
            map,
            currentUserId: currentUserId,
            requestedPage: page,
          );
          return {
            'success': true,
            'data': model,
            'rawLesson': map['lesson'],
            'raw': map,
          };
        }
        return {'success': false, 'message': 'صيغة استجابة غير متوقعة'};
      } else {
        final errorData = response.data;
        return {
          'success': false,
          'message': extractErrorMessage(errorData, 'فشل في جلب تفاصيل الدرس'),
        };
      }
    } on DioException catch (e) {
      print("❌ GetLessonDetail DioException: ${e.response?.data}");
      final errorData = e.response?.data;
      return {
        'success': false,
        'message': extractErrorMessage(errorData, e.message ?? 'حدث خطأ ما'),
      };
    } catch (e) {
      print("❌ GetLessonDetail Unexpected error: $e");
      return {'success': false, 'message': 'حدث خطأ غير متوقع'};
    }
  }

  Future<Map<String, dynamic>> postComment(
    int lessonId,
    String comment, {
    int? currentUserId,
  }) async {
    try {
      final response = await lessonDetailService.postComment(lessonId, comment);
      print("✅ PostComment Status: ${response.statusCode}");
      print("✅ PostComment Data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final unwrapped = unwrapResource(response.data);
        if (unwrapped != null) {
          return {
            'success': true,
            'data': LessonCommentModel.fromJson(
              unwrapped,
              currentUserId: currentUserId,
            ),
          };
        }
        return {'success': false, 'message': 'صيغة استجابة غير متوقعة'};
      } else {
        return {
          'success': false,
          'message': extractErrorMessage(response.data, 'فشل في إضافة التعليق'),
        };
      }
    } on DioException catch (e) {
      print("❌ PostComment DioException: ${e.response?.data}");
      return {
        'success': false,
        'message': extractErrorMessage(
          e.response?.data,
          e.message ?? 'حدث خطأ ما',
        ),
      };
    } catch (e) {
      print("❌ PostComment Unexpected error: $e");
      return {'success': false, 'message': 'حدث خطأ غير متوقع'};
    }
  }

  Future<Map<String, dynamic>> updateComment(
    int commentId,
    String comment, {
    int? currentUserId,
  }) async {
    try {
      final response = await lessonDetailService.updateComment(
        commentId,
        comment,
      );
      print("✅ UpdateComment Status: ${response.statusCode}");
      print("✅ UpdateComment Data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final unwrapped = unwrapResource(response.data);
        if (unwrapped != null) {
          return {
            'success': true,
            'data': LessonCommentModel.fromJson(
              unwrapped,
              currentUserId: currentUserId,
            ),
          };
        }
        return {'success': false, 'message': 'صيغة استجابة غير متوقعة'};
      } else {
        return {
          'success': false,
          'message': extractErrorMessage(response.data, 'فشل في تعديل التعليق'),
        };
      }
    } on DioException catch (e) {
      print("❌ UpdateComment DioException: ${e.response?.data}");
      return {
        'success': false,
        'message': extractErrorMessage(
          e.response?.data,
          e.message ?? 'حدث خطأ ما',
        ),
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
        return {
          'success': false,
          'message': extractErrorMessage(response.data, 'فشل في حذف التعليق'),
        };
      }
    } on DioException catch (e) {
      print("❌ DeleteComment DioException: ${e.response?.data}");
      return {
        'success': false,
        'message': extractErrorMessage(
          e.response?.data,
          e.message ?? 'حدث خطأ ما',
        ),
      };
    } catch (e) {
      print("❌ DeleteComment Unexpected error: $e");
      return {'success': false, 'message': 'حدث خطأ غير متوقع'};
    }
  }
}
