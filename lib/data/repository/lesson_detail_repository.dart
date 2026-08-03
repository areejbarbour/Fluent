import 'package:dio/dio.dart';
import 'package:fluent/helper/api_error_helper.dart';
import '../models/lesson_detail_model.dart';
import 'package:fluent/data/services/lesson_detail_service.dart';

class LessonDetailRepository {
  final LessonDetailService lessonDetailService;
  LessonDetailRepository(this.lessonDetailService);

  /// يستخرج رسالة خطأ واضحة من استجابة Laravel (message أو errors.comment)
  static String extractErrorMessage(dynamic errorData, String fallback) {
    return ApiErrorHelper.extract(
      errorData,
      fallback,
      preferredKeys: const ['comment', 'lesson', 'message'],
    );
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
        return {'success': false, 'message': 'Unexpected response format'};
      } else {
        final errorData = response.data;
        return {
          'success': false,
          'message': extractErrorMessage(
            errorData,
            'Failed to load lesson details',
          ),
        };
      }
    } on DioException catch (e) {
      print("❌ GetLessonDetail DioException: ${e.response?.data}");
      final errorData = e.response?.data;
      return {
        'success': false,
        'message': extractErrorMessage(
          errorData,
          e.message ?? 'Something went wrong',
        ),
      };
    } catch (e) {
      print("❌ GetLessonDetail Unexpected error: $e");
      return {'success': false, 'message': 'An unexpected error occurred'};
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
        return {'success': false, 'message': 'Unexpected response format'};
      } else {
        return {
          'success': false,
          'message': extractErrorMessage(
            response.data,
            'Failed to add comment',
          ),
        };
      }
    } on DioException catch (e) {
      print("❌ PostComment DioException: ${e.response?.data}");
      return {
        'success': false,
        'message': extractErrorMessage(
          e.response?.data,
          e.message ?? 'Something went wrong',
        ),
      };
    } catch (e) {
      print("❌ PostComment Unexpected error: $e");
      return {'success': false, 'message': 'An unexpected error occurred'};
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
        return {'success': false, 'message': 'Unexpected response format'};
      } else {
        return {
          'success': false,
          'message': extractErrorMessage(
            response.data,
            'Failed to update comment',
          ),
        };
      }
    } on DioException catch (e) {
      print("❌ UpdateComment DioException: ${e.response?.data}");
      return {
        'success': false,
        'message': extractErrorMessage(
          e.response?.data,
          e.message ?? 'Something went wrong',
        ),
      };
    } catch (e) {
      print("❌ UpdateComment Unexpected error: $e");
      return {'success': false, 'message': 'An unexpected error occurred'};
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
          'message': extractErrorMessage(
            response.data,
            'Failed to delete comment',
          ),
        };
      }
    } on DioException catch (e) {
      print("❌ DeleteComment DioException: ${e.response?.data}");
      return {
        'success': false,
        'message': extractErrorMessage(
          e.response?.data,
          e.message ?? 'Something went wrong',
        ),
      };
    } catch (e) {
      print("❌ DeleteComment Unexpected error: $e");
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }
}
