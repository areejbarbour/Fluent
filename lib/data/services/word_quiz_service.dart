import 'package:dio/dio.dart';
import 'package:fluent/constants/strings.dart';

/// Backend (student only):
/// - GET  /api/words/quiz
/// - POST /api/words/{word}/quiz_check  body: { "answer_id": int }
class WordQuizService {
  final Dio dio;
  WordQuizService(this.dio);

  Future<Response> getQuiz() async {
    return await dio.get(
      apiWordsQuiz,
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  Future<Response> checkAnswer({
    required int wordId,
    required int answerId,
  }) async {
    return await dio.post(
      apiWordQuizCheck(wordId),
      data: {'answer_id': answerId},
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }
}
