import 'package:dio/dio.dart';
import 'package:fluent/constants/strings.dart';

class LessonService {
  final Dio dio;
  LessonService(this.dio);

  // ✅ GET /api/getTeacherCourses
  Future<Response> getTeacherCourses() async {
    return await dio.get(
      apiGetTeacherCourses,
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  // ✅ GET /api/lessons/{course}
  Future<Response> getLessons(int courseId, {int page = 1}) async {
    return await dio.get(
      apiTeacherLessons(courseId),
      queryParameters: {'page': page},
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  // ✅ POST /api/lessons/{course}  (multipart, includes the video file)
  Future<Response> createLesson(int courseId, FormData formData) async {
    return await dio.post(
      apiTeacherLessons(courseId),
      data: formData,
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  // ✅ POST /api/lessons/{lesson}/update
  Future<Response> updateLesson(int lessonId, FormData formData) async {
    return await dio.post(
      apiLessonUpdate(lessonId),
      data: formData,
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }
    // ✅ إضافة دالة الحذف لتطابق الـ Backend
  Future<Response> deleteLesson(int lessonId) async {
    return await dio.delete(
      '/api/lessons/$lessonId/delete', // ✅ المسار الصحيح حسب الـ Backend
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }
}
