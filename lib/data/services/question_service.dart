import 'package:dio/dio.dart';
import 'package:fluent/constants/strings.dart';

class QuestionService {
  final Dio dio;
  QuestionService(this.dio);

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

  Future<Response> filterQuestions({
    int page = 1,
    String? type,
    String? difficulty,
    int? minScore,
    int? maxScore,
    String? search,
    int? courseId,
    bool? onlyEligible,
    String? sort,
  }) async {
    final Map<String, dynamic> body = {};

    if (type != null && type.isNotEmpty) body['type'] = type;
    if (difficulty != null && difficulty.isNotEmpty) {
      body['difficulty'] = difficulty;
    }
    if (minScore != null) body['min_score'] = minScore;
    if (maxScore != null) body['max_score'] = maxScore;
    if (search != null && search.trim().isNotEmpty) {
      body['search'] = search.trim();
    }
    if (courseId != null) body['course_id'] = courseId;

    // ✅ الباك: course_id required_with only_eligible
    // لا ترسل only_eligible أبداً بدون course_id
    if (courseId != null && onlyEligible != null) {
      body['only_eligible'] = onlyEligible;
    }

    if (sort != null && sort.isNotEmpty) body['sort'] = sort;

    return await dio.post(
      apiQuestionsFilter,
      data: body,
      queryParameters: {'page': page}, // ✅ مهم جداً للـ Pagination
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }
}
