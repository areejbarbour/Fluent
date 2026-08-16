import 'package:fluent/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Unified student SnackBar — same design as podcasts screen.
enum AppSnackType { success, error, info, warning }

void showAppSnackBar(
  BuildContext context,
  String message, {
  AppSnackType type = AppSnackType.info,
  Duration duration = const Duration(seconds: 3),
  bool haptic = true,
}) {
  if (!context.mounted) return;

  if (haptic) {
    switch (type) {
      case AppSnackType.success:
        HapticFeedback.lightImpact();
        break;
      case AppSnackType.error:
        HapticFeedback.mediumImpact();
        break;
      default:
        HapticFeedback.selectionClick();
    }
  }

  final IconData icon;
  final Color iconColor;
  switch (type) {
    case AppSnackType.success:
      icon = Icons.check_circle_rounded;
      iconColor = const Color(0xFF4ADE80);
      break;
    case AppSnackType.error:
      icon = Icons.error_outline_rounded;
      iconColor = Colors.redAccent;
      break;
    case AppSnackType.warning:
      icon = Icons.warning_amber_rounded;
      iconColor = AppColors.orange;
      break;
    case AppSnackType.info:
      icon = Icons.info_outline_rounded;
      iconColor = AppColors.sky;
      break;
  }

  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(.15),
            ),
            child: Icon(icon, color: iconColor, size: 18.sp),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12.5.sp,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.r),
      ),
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
      duration: duration,
    ),
  );
}
