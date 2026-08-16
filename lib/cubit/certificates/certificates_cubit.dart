import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/cubit/safe_cubit.dart';
import 'package:fluent/data/models/certificate_model.dart';
import 'package:fluent/data/repository/certificate_repository.dart';
import 'certificates_state.dart';

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
      emit(CertificatesSuccess(List.unmodifiable(_cache)));
    }
  }

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
