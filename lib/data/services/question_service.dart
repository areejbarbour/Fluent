import 'package:dio/dio.dart';
import 'package:fluent/constants/strings.dart';

class QuestionService {
  final Dio dio;
  QuestionService(this.dio);

  // ✅ GET /api/questions  (paginated active)
  Future<Response> getQuestions({int page = 1}) async {
    return await dio.get(
      apiQuestions,
      queryParameters: {'page': page},
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  // ✅ GET /api/questions/deprecated
  Future<Response> getDeprecatedQuestions({int page = 1}) async {
    return await dio.get(
      apiDeprecatedQuestions,
      queryParameters: {'page': page},
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  // ✅ GET /api/questions/{id}
  Future<Response> getQuestion(int id) async {
    return await dio.get(
      apiQuestionDetail(id),
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  // ✅ POST /api/questions  (multipart if files included)
  Future<Response> createQuestion(FormData formData) async {
    return await dio.post(
      apiQuestions,
      data: formData,
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  // ✅ POST /api/questions/{id}  (backend uses POST for updates)
  Future<Response> updateQuestion(int id, FormData formData) async {
    return await dio.post(
      apiQuestionDetail(id),
      data: formData,
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  // ✅ GET /api/questions/{id}/checkStatus
  Future<Response> checkStatus(int id) async {
    return await dio.get(
      apiQuestionCheckStatus(id),
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  // ✅ GET /api/questions/{id}/delete
  Future<Response> deleteQuestion(int id) async {
    return await dio.get(
      apiQuestionDelete(id),
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  // ✅ GET /api/questions/{id}/blocking-tests
  Future<Response> blockingTests(int id) async {
    return await dio.get(
      apiQuestionBlockingTests(id),
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }
}