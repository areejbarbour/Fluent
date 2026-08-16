import 'dart:ui';

import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/constants/strings.dart';
import 'package:fluent/data/models/certificate_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

/// Celebration dialog shown after a student passes a **level** final test.
///
/// Backend issues the certificate in `AttemptService::finishAttempt` and the
/// finish response now includes `reward.certificate_url` + `reward.user_level_id`.
/// When [certificateUrl] is available the primary action opens it directly.
class CertificateEarnedDialog extends StatelessWidget {
  /// Optional level display name (e.g. "A1").
  final String? levelName;

  /// Score percent from the finish response.
  final int? scorePercent;

  /// Direct download/view URL from finish (or resolved via retry).
  final String? certificateUrl;

  const CertificateEarnedDialog({
    super.key,
    this.levelName,
    this.scorePercent,
    this.certificateUrl,
  });

  /// Shows the dialog once.
  /// Returns `true` if the user chose the primary certificate action.
  static Future<bool> show(
    BuildContext context, {
    String? levelName,
    int? scorePercent,
    String? certificateUrl,
  }) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Certificate',
      barrierColor: Colors.black.withOpacity(0.72),
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (_, __, ___) => CertificateEarnedDialog(
        levelName: levelName,
        scorePercent: scorePercent,
        certificateUrl: certificateUrl,
      ),
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(scale: curved, child: child),
        );
      },
    );
    return result == true;
  }

  bool get _hasUrl {
    final u = certificateUrl?.trim();
    return u != null && u.isNotEmpty;
  }

  Future<void> _onPrimary(BuildContext context) async {
    HapticFeedback.lightImpact();
    if (_hasUrl) {
      final normalized = CertificateModel.normalizeMediaUrl(certificateUrl);
      final uri = normalized == null ? null : Uri.tryParse(normalized);
      if (uri != null) {
        final ok = await canLaunchUrl(uri);
        if (ok) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
      if (context.mounted) Navigator.of(context).pop(true);
      return;
    }
    // Fallback: no URL yet → go to certificates list.
    if (context.mounted) Navigator.of(context).pop(true);
  }

  void _continue(BuildContext context) {
    HapticFeedback.selectionClick();
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final level = (levelName != null && levelName!.trim().isNotEmpty)
        ? levelName!.trim()
        : 'your level';

    final primaryLabel = _hasUrl ? 'Open certificate' : 'View certificates';
    final bodyText = _hasUrl
        ? 'You completed $level. Your official certificate is ready — open it now.'
        : 'You completed $level. Your official certificate has been issued and is ready in your profile.';

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 22.w),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(maxWidth: 400.w),
                padding: EdgeInsets.fromLTRB(22.w, 28.h, 22.w, 22.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28.r),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF0A4A66).withOpacity(0.96),
                      AppColors.dark.withOpacity(0.98),
                      const Color(0xFF012A3D).withOpacity(0.98),
                    ],
                  ),
                  border: Border.all(color: Colors.white.withOpacity(0.16)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.yellow.withOpacity(0.28),
                      blurRadius: 40,
                      spreadRadius: 2,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 88.w,
                      height: 88.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.yellow,
                            AppColors.orange,
                            AppColors.lightOrange,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.yellow.withOpacity(0.55),
                            blurRadius: 28,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.workspace_premium_rounded,
                        color: AppColors.dark,
                        size: 46.sp,
                      ),
                    ),
                    SizedBox(height: 18.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 5.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.yellow.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: AppColors.yellow.withOpacity(0.35),
                        ),
                      ),
                      child: Text(
                        'CERTIFICATE EARNED',
                        style: GoogleFonts.poppins(
                          color: AppColors.yellow,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Congratulations!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      bodyText,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.72),
                        fontSize: 13.5.sp,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (scorePercent != null) ...[
                      SizedBox(height: 14.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 10.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.10),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.insights_rounded,
                              color: AppColors.sky,
                              size: 18.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Final score  $scorePercent%',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: 22.h),
                    SizedBox(
                      width: double.infinity,
                      height: 52.h,
                      child: ElevatedButton(
                        onPressed: () => _onPrimary(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.yellow,
                          foregroundColor: AppColors.dark,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _hasUrl
                                  ? Icons.open_in_new_rounded
                                  : Icons.workspace_premium_rounded,
                              size: 20.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              primaryLabel,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w800,
                                fontSize: 15.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextButton(
                      onPressed: () => _continue(context),
                      child: Text(
                        'Continue',
                        style: GoogleFonts.poppins(
                          color: Colors.white60,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Navigates to the certificates list (student Profile → Certificates).
Future<void> openCertificatesScreen(
  BuildContext context, {
  bool expectFresh = false,
}) async {
  if (!context.mounted) return;
  await Navigator.of(context).pushNamed(
    certificatesRoute,
    arguments: <String, dynamic>{'expectFresh': expectFresh},
  );
}

/// Opens a certificate media URL in an external browser/viewer.
Future<bool> openCertificateUrl(String? url) async {
  final normalized = CertificateModel.normalizeMediaUrl(url);
  if (normalized == null) return false;
  final uri = Uri.tryParse(normalized);
  if (uri == null) return false;
  final ok = await canLaunchUrl(uri);
  if (!ok) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
