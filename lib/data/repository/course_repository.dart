import 'package:dio/dio.dart';
import 'package:fluent/helper/api_error_helper.dart';
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
        return {'success': false, 'message': 'Unexpected response format'};
      } else {
        final errorData = response.data;
        return ApiErrorHelper.failure(errorData, 'Failed to load courses');
      }
    } on DioException catch (e) {
      print("❌ GetStudentCourses DioException: ${e.response?.data}");
      final errorData = e.response?.data;
      return ApiErrorHelper.fromDio(e, 'Something went wrong');
    } catch (e) {
      print("❌ GetStudentCourses Unexpected error: $e");
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }
}
