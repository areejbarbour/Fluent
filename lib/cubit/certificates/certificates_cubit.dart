import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/cubit/safe_cubit.dart';
import 'package:fluent/data/models/certificate_model.dart';
import 'package:fluent/data/repository/certificate_repository.dart';
import 'certificates_state.dart';

/// Certificates flow aligned with backend:
/// - List: GET /api/certificates
/// - Issue happens server-side on level-test pass (AttemptService)
/// - Optional re-fetch/issue: GET /api/user-levels/{userLevel}/certificate
class CertificatesCubit extends SafeCubit<CertificatesState> {
  final CertificateRepository repository;

  CertificatesCubit(this.repository) : super(const CertificatesInitial());

  List<CertificateModel> _cache = [];

  Future<void> fetchCertificates({bool silent = false}) async {
    if (!silent) {
      emit(const CertificatesLoading());
    }
    final result = await repository.getCertificates();
    if (result['success'] == true && result['data'] is List<CertificateModel>) {
      _cache = result['data'] as List<CertificateModel>;
      emit(CertificatesSuccess(List.unmodifiable(_cache)));
    } else if (!silent) {
      emit(
        CertificatesFailure(
          result['message']?.toString() ?? 'Failed to load certificates',
        ),
      );
    } else {
      // Keep previous list visible on silent refresh failure.
      emit(CertificatesSuccess(List.unmodifiable(_cache)));
    }
  }

  /// GET /api/user-levels/{userLevel}/certificate
  /// Backend issues the certificate if missing (idempotent) when UserLevel is completed.
  Future<void> downloadForUserLevel(int userLevelId) async {
    emit(
      CertificateDownloadLoading(
        certificates: List.unmodifiable(_cache),
        userLevelId: userLevelId,
      ),
    );
    final result = await repository.getUserLevelCertificate(userLevelId);
    if (result['success'] == true && result['data'] is String) {
      emit(
        CertificateDownloadSuccess(
          certificates: List.unmodifiable(_cache),
          downloadUrl: result['data'] as String,
        ),
      );
      // Refresh list in background so card download_url updates.
      await fetchCertificates(silent: true);
    } else {
      emit(
        CertificateDownloadFailure(
          certificates: List.unmodifiable(_cache),
          message: result['message']?.toString() ?? 'Failed to get certificate',
        ),
      );
    }
  }
}
