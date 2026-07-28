

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