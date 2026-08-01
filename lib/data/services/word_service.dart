import 'package:dio/dio.dart';
import 'package:fluent/constants/strings.dart';

class WordService {
  final Dio dio;
  WordService(this.dio);

  /// POST /api/words/{lesson}/create
  /// Body must be multipart when uploading audio (required by backend).
  Future<Response> createWord(int lessonId, FormData formData) async {
    return await dio.post(
      apiCreateWord(lessonId),
      data: formData,
      options: Options(
        headers: {
          'Accept': 'application/json',
          // Do NOT set Content-Type — Dio sets multipart boundary automatically.
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  /// POST /api/words/{word}/update
  /// multipart; audio is optional.
  Future<Response> updateWord(int wordId, FormData formData) async {
    return await dio.post(
      apiUpdateWord(wordId),
      data: formData,
      options: Options(
        headers: {'Accept': 'application/json'},
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
