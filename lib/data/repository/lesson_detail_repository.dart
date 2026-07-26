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
}