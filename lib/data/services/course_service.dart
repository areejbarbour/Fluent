import 'package:dio/dio.dart';
import 'package:fluent/constants/strings.dart';

class CourseService {
  final Dio dio;
  CourseService(this.dio);

  Future<Response> getStudentCourses(int levelId) async {
    return await dio.get(
      apiGetStudentCourses(levelId),
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }
}