import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/cubit/certificates/certificates_cubit.dart';
import 'package:fluent/cubit/certificates/certificates_state.dart';
import 'package:fluent/data/models/certificate_model.dart';
import 'package:fluent/presentation/widgets/app_backdrop.dart';
import 'package:fluent/presentation/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({super.key});

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  @override
  void initState() {
    super.initState();
    // Backend already issues the certificate on level pass; list comes from
    // GET /api/certificates (download_url from Spatie media).
    context.read<CertificatesCubit>().fetchCertificates();
    // One short retry: media may not be visible for a moment after finish.
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      final state = context.read<CertificatesCubit>().state;
      final empty = state is CertificatesSuccess && state.certificates.isEmpty;
      if (empty || state is CertificatesFailure) {
        context.read<CertificatesCubit>().fetchCertificates(silent: true);
      }
    });
  }

  Future<void> _openUrl(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      if (mounted) {
        showAppSnackBar(
          context,
          'Certificate file is not available yet. Please try again.',
          type: AppSnackType.error,
        );
      }
      return;
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null) {
      if (mounted) {
        showAppSnackBar(
          context,
          'Invalid certificate URL',
          type: AppSnackType.error,
        );
      }
      return;
    }
    try {
      final ok = await canLaunchUrl(uri);
      if (ok) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        showAppSnackBar(
          context,
          'Cannot open certificate URL',
          type: AppSnackType.error,
        );
      }
    } catch (_) {
      if (mounted) {
        showAppSnackBar(
          context,
          'Cannot open certificate URL',
          type: AppSnackType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // AppBackdrop has NO child param — it is a background layer only.
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Stack(
        children: [
          const AppBackdrop(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Certificates',
                        style: GoogleFonts.poppins(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: BlocConsumer<CertificatesCubit, CertificatesState>(
                    listener: (context, state) {
                      if (state is CertificateDownloadSuccess) {
                        _openUrl(state.downloadUrl);
                      } else if (state is CertificateDownloadFailure) {
                        showAppSnackBar(
                          context,
                          state.message,
                          type: AppSnackType.error,
                        );
                      }
                    },
                    builder: (context, state) {
                      if (state is CertificatesLoading) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }
                      if (state is CertificatesFailure) {
                        return _ErrorView(
                          message: state.message,
                          onRetry: () => context
                              .read<CertificatesCubit>()
                              .fetchCertificates(),
                        );
                      }

                      final list = switch (state) {
                        CertificatesSuccess s => s.certificates,
                        CertificateDownloadLoading s => s.certificates,
                        CertificateDownloadSuccess s => s.certificates,
                        CertificateDownloadFailure s => s.certificates,
                        _ => <CertificateModel>[],
                      };

                      if (list.isEmpty) {
                        return Center(
                          child: Text(
                            'No certificates yet.\nComplete a level to earn one.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              color: Colors.white70,
                            ),
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () => context
                            .read<CertificatesCubit>()
                            .fetchCertificates(),
                        child: ListView.separated(
                          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                          itemCount: list.length,
                          separatorBuilder: (_, __) => SizedBox(height: 12.h),
                          itemBuilder: (context, i) {
                            final c = list[i];
                            return _CertificateCard(
                              certificate: c,
                              onDownload: c.hasDownloadUrl
                                  ? () => _openUrl(c.downloadUrl!)
                                  : null,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  final CertificateModel certificate;
  final VoidCallback? onDownload;

  const _CertificateCard({required this.certificate, this.onDownload});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.workspace_premium,
                color: AppColors.orange,
                size: 28.sp,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  certificate.levelName,
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            certificate.certificateNumber,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Issued: ${certificate.issuedAt}',
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: AppColors.dark.withOpacity(0.6),
            ),
          ),
          if (onDownload != null) ...[
            SizedBox(height: 12.h),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onDownload,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: Text(
                  'Download',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
