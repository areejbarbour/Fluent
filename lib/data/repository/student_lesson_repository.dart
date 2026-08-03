import 'package:dio/dio.dart';
import 'package:fluent/helper/api_error_helper.dart';
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
          return {'success': true, 'data': StudentLessonsModel.fromJson(data)};
        }
        return {'success': false, 'message': 'Unexpected response format'};
      } else {
        final errorData = response.data;
        return ApiErrorHelper.failure(errorData, 'Failed to load lessons');
      }
    } on DioException catch (e) {
      print("❌ GetStudentLessons DioException: ${e.response?.data}");
      final errorData = e.response?.data;
      return ApiErrorHelper.fromDio(e, 'Something went wrong');
    } catch (e) {
      print("❌ GetStudentLessons Unexpected error: $e");
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }
}
