import 'package:dio/dio.dart';
import 'package:fluent/data/models/certificate_model.dart';
import 'package:fluent/data/services/certificate_service.dart';
import 'package:fluent/helper/api_error_helper.dart';

class CertificateRepository {
  final CertificateService certificateService;
  CertificateRepository(this.certificateService);

  /// GET /api/certificates → List<CertificateModel>
  /// Backend returns a bare JSON array (not wrapped).
  Future<Map<String, dynamic>> getCertificates() async {
    try {
      final res = await certificateService.getCertificates();
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = res.data;
        if (data is List) {
          final list = data
              .whereType<Map>()
              .map(
                (e) => CertificateModel.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList();
          return {'success': true, 'data': list};
        }
        return {'success': false, 'message': 'Unexpected response format'};
      }
      return ApiErrorHelper.failure(res.data, 'Failed to load certificates');
    } on DioException catch (e) {
      return ApiErrorHelper.fromDio(e, 'Failed to load certificates');
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }

  /// GET /api/user-levels/{userLevel}/certificate
  /// Backend success: { "download_url": "..." }
  /// 422: { "error": "Level not completed yet." }
  /// 503: { "error": "Certificate generation temporarily failed..." }
  /// 403: forbidden (not owner)
  Future<Map<String, dynamic>> getUserLevelCertificate(int userLevelId) async {
    try {
      final res = await certificateService.getUserLevelCertificate(userLevelId);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = res.data;
        if (data is Map && data['download_url'] != null) {
          final normalized = CertificateModel.normalizeMediaUrl(
            data['download_url'].toString(),
          );
          if (normalized == null) {
            return {
              'success': false,
              'message': 'Certificate file is not available yet',
            };
          }
          return {'success': true, 'data': normalized};
        }
        return {'success': false, 'message': 'Unexpected response format'};
      }
      return ApiErrorHelper.failure(res.data, 'Failed to get certificate');
    } on DioException catch (e) {
      return ApiErrorHelper.fromDio(e, 'Failed to get certificate');
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred'};
    }
  }
}
