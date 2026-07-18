import 'package:dio/dio.dart';
import '../models/course_model.dart';
import 'package:fluent/data/services/course_service.dart';

class CourseRepository {
  final CourseService courseService;
  CourseRepository(this.courseService);

  Future<Map<String, dynamic>> getStudentCourses(int levelId) async {
    try {
      final response = await courseService.getStudentCourses(levelId);
      print("✅ GetStudentCourses Status: ${response.statusCode}");
      print("✅ GetStudentCourses Data: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return {'success': true, 'data': StudentCoursesModel.fromJson(data)};
        }
        return {'success': false, 'message': 'صيغة استجابة غير متوقعة'};
      } else {
        final errorData = response.data;
        return {
          'success': false,
          'message': errorData is Map
              ? errorData['message'] ?? 'فشل في جلب الكورسات'
              : 'فشل في جلب الكورسات',
        };
      }
    } on DioException catch (e) {
      print("❌ GetStudentCourses DioException: ${e.response?.data}");
      final errorData = e.response?.data;
      return {
        'success': false,
        'message': errorData is Map
            ? errorData['message'] ?? 'حدث خطأ ما'
            : e.message ?? 'حدث خطأ ما',
      };
    } catch (e) {
      print("❌ GetStudentCourses Unexpected error: $e");
      return {'success': false, 'message': 'حدث خطأ غير متوقع'};
    }
  }
}