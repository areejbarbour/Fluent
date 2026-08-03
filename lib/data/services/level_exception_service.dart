import 'package:dio/dio.dart';
import 'package:fluent/constants/strings.dart';

class LevelExceptionService {
  final Dio dio;
  LevelExceptionService(this.dio);

  Future<Response> getPending() async {
    return await dio.get(
      apiLevelExceptionsPending,
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  Future<Response> getRejected() async {
    return await dio.get(
      apiLevelExceptionsRejected,
      options: Options(
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
  }

  Future<Response> getApproved() async {
    return await dio.get(
      apiLevelExceptionsApproved,
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
  final formData = FormData.fromMap({
    'reason': reason,
    if (attachments != null && attachments.isNotEmpty)
      'attachments[]': attachments,
  });

  return await dio.post(
    apiUpdateLevelException(id),
    data: formData,
    options: Options(
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'multipart/form-data',
      },
      validateStatus: (status) => status != null && status < 500,
    ),
  );
}

// Future<Response> createException({
//   required int levelId,
//   required String reason,
//   List<MultipartFile>? attachments,
// }) async {
//   final formData = FormData.fromMap({
//     'reason': reason,
//     if (attachments != null && attachments.isNotEmpty)
//       'attachments[]': attachments,
//   });

//   return await dio.post(
//     apiCreateLevelException(levelId),
//     data: formData,
//     options: Options(
//       headers: {
//         'Accept': 'application/json',
//         'Content-Type': 'multipart/form-data',
//       },
//       validateStatus: (status) => status != null && status < 500,
//     ),
//   );
// }

Future<Response> createException({
  required int levelId,
  required String reason,
  List<MultipartFile>? attachments,
}) async {
  final formData = FormData.fromMap({
    'reason': reason,
  });

  if (attachments != null && attachments.isNotEmpty) {
    for (final file in attachments) {
      formData.files.add(MapEntry('attachments[]', file));
    }
  }

  return await dio.post(
    apiCreateLevelException(levelId),
    data: formData,
    options: Options(
      headers: {
        'Accept': 'application/json',
      },
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
}