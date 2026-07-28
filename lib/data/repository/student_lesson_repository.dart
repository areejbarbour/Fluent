import 'package:dio/dio.dart';
import '../models/student_lesson_model.dart';
import 'package:fluent/data/services/student_lesson_service.dart';

class StudentLessonRepository {
  final StudentLessonService studentLessonService;
  StudentLessonRepository(this.studentLessonService);

  Future<Map<String, dynamic>> getStudentLessons(int courseId) async {
    try {
      final response = await studentLessonService.getStudentLessons(courseId);
      print("✅ GetStudentLessons Status: ${response.statusCode}");
      print("✅ GetStudentLessons Data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return {
            'success': true,
            'data': StudentLessonsModel.fromJson(data),
          };
        }
        return {'success': false, 'message': 'صيغة استجابة غير متوقعة'};
      } else {
        final errorData = response.data;
        return {
          'success': false,
          'message': errorData is Map
              ? errorData['message'] ?? 'فشل في جلب الدروس'
              : 'فشل في جلب الدروس',
        };
      }
    } on DioException catch (e) {
      print("❌ GetStudentLessons DioException: ${e.response?.data}");
      final errorData = e.response?.data;
      return {
        'success': false,
        'message': errorData is Map
            ? errorData['message'] ?? 'حدث خطأ ما'
            : e.message ?? 'حدث خطأ ما',
      };
    } catch (e) {
      print("❌ GetStudentLessons Unexpected error: $e");
      return {'success': false, 'message': 'حدث خطأ غير متوقع'};
    }
  }
}