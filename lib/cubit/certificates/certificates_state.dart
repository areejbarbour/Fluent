import 'package:fluent/data/models/certificate_model.dart';

abstract class CertificatesState {
  const CertificatesState();
}

class CertificatesInitial extends CertificatesState {
  const CertificatesInitial();
}

class CertificatesLoading extends CertificatesState {
  const CertificatesLoading();
}

class CertificatesSuccess extends CertificatesState {
  final List<CertificateModel> certificates;
  const CertificatesSuccess(this.certificates);
}

class CertificatesFailure extends CertificatesState {
  final String message;
  const CertificatesFailure(this.message);
}

class CertificateDownloadLoading extends CertificatesState {
  final List<CertificateModel> certificates;
  final int userLevelId;
  const CertificateDownloadLoading({
    required this.certificates,
    required this.userLevelId,
  });
}

class CertificateDownloadSuccess extends CertificatesState {
  final List<CertificateModel> certificates;
  final String downloadUrl;
  const CertificateDownloadSuccess({
    required this.certificates,
    required this.downloadUrl,
  });
}

class CertificateDownloadFailure extends CertificatesState {
  final List<CertificateModel> certificates;
  final String message;
  const CertificateDownloadFailure({
    required this.certificates,
    required this.message,
  });
}
