import 'package:dio/dio.dart';
import 'package:fluent/constants/strings.dart';

class WordService {
  final Dio dio;
  WordService(this.dio);

  /// POST /api/words/{lesson}/create
  Future<Response> createWord(int lessonId, Map<String, dynamic> body) async {
    return await dio.post(
      apiCreateWord(lessonId),
      data: body,
      options: Options(
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  /// POST /api/words/{word}/update
  Future<Response> updateWord(int wordId, Map<String, dynamic> body) async {
    return await dio.post(
      apiUpdateWord(wordId),
      data: body,
      options: Options(
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  /// DELETE /api/words/{word}/delete
  Future<Response> deleteWord(int wordId) async {
    return await dio.delete(
      apiDeleteWord(wordId),
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }
}
