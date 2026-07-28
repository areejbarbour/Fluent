import 'package:dio/dio.dart';
import 'package:fluent/constants/strings.dart';

class LessonDetailService {
  final Dio dio;
  LessonDetailService(this.dio);

  Future<Response> getLessonDetail(int lessonId) async {
    return await dio.get(
      apiLessonDetail(lessonId),
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }
}