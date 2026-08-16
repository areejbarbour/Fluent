import 'package:dio/dio.dart';
import 'package:fluent/constants/strings.dart';

/// Thin Dio layer — matches backend CertificateController routes exactly.
///
/// Routes (auth:sanctum + role:student):
/// - GET /api/certificates
/// - GET /api/user-levels/{userLevel}/certificate
class CertificateService {
  final Dio dio;
  CertificateService(this.dio);

  Options get _opts => Options(
    headers: {'Accept': 'application/json'},
    // Include 4xx and 503 so repository can read Laravel { "error": "..." }.
    validateStatus: (status) =>
        status != null && (status < 500 || status == 503),
  );

  /// GET /api/certificates → bare JSON array of certificates
  Future<Response> getCertificates() {
    return dio.get(apiCertificates, options: _opts);
  }

  /// GET /api/user-levels/{userLevel}/certificate
  /// 200: { "download_url": "..." }
  /// 422: { "error": "Level not completed yet." }
  /// 503: { "error": "Certificate generation temporarily failed..." }
  Future<Response> getUserLevelCertificate(int userLevelId) {
    return dio.get(apiUserLevelCertificate(userLevelId), options: _opts);
  }
}
