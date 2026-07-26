import 'package:dio/dio.dart';
import 'package:fluent/constants/strings.dart';

class StudentLessonService {
  final Dio dio;
  StudentLessonService(this.dio);

  Future<Response> getStudentLessons(int courseId) async {
    return await dio.get(
      apiGetStudentLessons(courseId),
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }
}