import 'package:dio/dio.dart';
import 'package:fluent/constants/strings.dart';

class LessonDetailService {
  final Dio dio;
  LessonDetailService(this.dio);

  /// جلب تفاصيل الدرس + التعليقات.
  /// [teacher] true → `/api/lessons/{id}/details` (مسار المعلّم)
  /// false → `/api/lessons/{id}/detail` (مسار الطالب)
  Future<Response> getLessonDetail(
    int lessonId, {
    int page = 1,
    bool teacher = false,
  }) async {
    final path = teacher
        ? apiLessonDetails(lessonId)
        : apiLessonDetail(lessonId);
    // Laravel paginate(10) يقرأ ?page= من الـ request
    return await dio.get(
      path,
      queryParameters: {'page': page},
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  // ✅ POST /api/comments/{lessonId}  →  { "comment": "..." }
  Future<Response> postComment(int lessonId, String comment) async {
    return await dio.post(
      apiCreateComment(lessonId),
      data: {'comment': comment},
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  // ✅ POST /api/comments/{commentId}/update  →  { "comment": "..." }
  Future<Response> updateComment(int commentId, String comment) async {
    return await dio.post(
      apiUpdateComment(commentId),
      data: {'comment': comment},
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  // ✅ DELETE /api/comments/{commentId}/delete
  Future<Response> deleteComment(int commentId) async {
    return await dio.delete(
      apiDeleteComment(commentId),
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }
}
