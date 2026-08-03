import 'package:dio/dio.dart';
import 'package:fluent/constants/strings.dart';

class LessonWordService {
  final Dio dio;
  LessonWordService(this.dio);

  Future<Response> getLessonWords(int lessonId) async {
    return await dio.get(
      apiLessonWords(lessonId),
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  Future<Response> moveToLearning(int wordId) async {
  return await dio.post(
    apiWordToLearning(wordId),
    options: Options(
      headers: {'Accept': 'application/json'},
      validateStatus: (status) => status != null && status < 500,
    ),
  );
}

Future<Response> moveToKnow(int wordId) async {
  return await dio.post(
    apiWordToKnow(wordId),
    options: Options(
      headers: {'Accept': 'application/json'},
      validateStatus: (status) => status != null && status < 500,
    ),
  );
}
}