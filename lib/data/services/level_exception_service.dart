import 'package:dio/dio.dart';
import 'package:fluent/constants/strings.dart';

class LevelExceptionService {
  final Dio dio;
  LevelExceptionService(this.dio);

  Future<Response> getPending({int page = 1}) async {
    return await dio.get(
      apiLevelExceptionsPending,
      queryParameters: {'page': page},
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  /// Backend status: in_review (admin started review)
  Future<Response> getInReview({int page = 1}) async {
    return await dio.get(
      apiLevelExceptionsInReview,
      queryParameters: {'page': page},
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  Future<Response> getRejected({int page = 1}) async {
    return await dio.get(
      apiLevelExceptionsRejected,
      queryParameters: {'page': page},
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  Future<Response> getApproved({int page = 1}) async {
    return await dio.get(
      apiLevelExceptionsApproved,
      queryParameters: {'page': page},
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  Future<Response> getDetails(int id) async {
    return await dio.get(
      apiLevelExceptionDetails(id),
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  Future<Response> updateException({
    required int id,
    required String reason,
    List<MultipartFile>? attachments,
  }) async {
    final formData = FormData.fromMap({'reason': reason});

    if (attachments != null && attachments.isNotEmpty) {
      for (final file in attachments) {
        formData.files.add(MapEntry('attachments[]', file));
      }
    }

    return await dio.post(
      apiUpdateLevelException(id),
      data: formData,
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  Future<Response> createException({
    required int levelId,
    required String reason,
    List<MultipartFile>? attachments,
  }) async {
    final formData = FormData.fromMap({'reason': reason});

    if (attachments != null && attachments.isNotEmpty) {
      for (final file in attachments) {
        formData.files.add(MapEntry('attachments[]', file));
      }
    }

    return await dio.post(
      apiCreateLevelException(levelId),
      data: formData,
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  Future<Response> deleteException(int id) async {
    return await dio.delete(
      apiDeleteLevelException(id),
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  /// DELETE /api/level-exceptions/{levelException}/attachments/{media}
  /// Backend allows this only when the request status is `pending`.
  Future<Response> deleteAttachment({
    required int exceptionId,
    required int mediaId,
  }) async {
    return await dio.delete(
      apiDeleteLevelExceptionAttachment(exceptionId, mediaId),
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }
}
