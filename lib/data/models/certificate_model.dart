import 'package:fluent/constants/strings.dart';

/// Single item from GET /api/certificates
/// Backend shape (CertificateService::getStudentCertificates):
/// {
///   "id": int,
///   "certificate_number": string,
///   "level_name": string,   // level name_en
///   "issued_at": "Y-m-d",
///   "download_url": string|null  // Spatie media URL
/// }
///
/// Certificate is issued server-side in AttemptService::finishAttempt when a
/// level test is passed. Finish API returns reward.certificate_url +
/// reward.user_level_id. If the URL is null, clients retry via
/// GET /api/user-levels/{id}/certificate (or load GET /api/certificates).
class CertificateModel {
  final int id;
  final String certificateNumber;
  final String levelName;
  final String issuedAt;
  final String? downloadUrl;

  const CertificateModel({
    required this.id,
    required this.certificateNumber,
    required this.levelName,
    required this.issuedAt,
    this.downloadUrl,
  });

  bool get hasDownloadUrl =>
      downloadUrl != null && downloadUrl!.trim().isNotEmpty;

  factory CertificateModel.fromJson(Map<String, dynamic> json) {
    final rawUrl = json['download_url']?.toString().trim();
    return CertificateModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      certificateNumber: json['certificate_number']?.toString() ?? '',
      levelName: json['level_name']?.toString() ?? '',
      issuedAt: json['issued_at']?.toString() ?? '',
      downloadUrl: normalizeMediaUrl(
        (rawUrl == null || rawUrl.isEmpty) ? null : rawUrl,
      ),
    );
  }

  /// Spatie may return absolute URL or a relative path like `/storage/...`.
  static String? normalizeMediaUrl(String? url) {
    if (url == null) return null;
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    if (trimmed.startsWith('/')) return '$base$trimmed';
    return '$base/$trimmed';
  }
}
