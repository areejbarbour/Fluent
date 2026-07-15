import 'package:flutter/material.dart';
import 'package:fluent/constants/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class QuestionUI {
  /// Color per question type
  static Color typeColor(String type) {
    switch (type.toUpperCase()) {
      case 'MCQ':
        return AppColors.sky;
      case 'FILL':
        return AppColors.orange;
      case 'ARRANGE':
        return AppColors.yellow;
      case 'PAIR':
        return Colors.purpleAccent;
      default:
        return Colors.white;
    }
  }

  /// Icon per question type
  static IconData typeIcon(String type) {
    switch (type.toUpperCase()) {
      case 'MCQ':
        return Icons.check_circle_outline;
      case 'FILL':
        return Icons.edit_note;
      case 'ARRANGE':
        return Icons.sort;
      case 'PAIR':
        return Icons.compare_arrows;
      default:
        return Icons.help_outline;
    }
  }

  /// **Label per question type** ← أضفناها الآن
  static String typeLabel(String type) {
    switch (type.toUpperCase()) {
      case 'MCQ':
        return 'Multiple Choice';
      case 'FILL':
        return 'Fill in the Blanks';
      case 'ARRANGE':
        return 'Arrange Words';
      case 'PAIR':
        return 'Matching Pairs';
      default:
        return type;
    }
  }

  /// Color per difficulty
  static Color difficultyColor(String difficulty) {
    switch (difficulty.toUpperCase()) {
      case 'EASY':
        return Colors.greenAccent;
      case 'MEDIUM':
        return AppColors.orange;
      case 'HARD':
        return Colors.redAccent;
      default:
        return Colors.white;
    }
  }

  /// Reusable glass container
  static Widget glass({
    required Widget child,
    EdgeInsetsGeometry? padding,
    double radius = 24,
    double opacity = 0.12,
    Color? borderColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius.r),
      child: Container(
        padding: padding ?? EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius.r),
          color: Colors.white.withOpacity(opacity),
          border: Border.all(
            color: borderColor ?? Colors.white.withOpacity(0.25),
          ),
          boxShadow: [
            BoxShadow(color: AppColors.sky.withOpacity(0.15), blurRadius: 20),
          ],
        ),
        child: child,
      ),
    );
  }

  /// Background gradient
  static BoxDecoration backgroundGradient() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.dark, AppColors.primary, AppColors.sky],
      ),
    );
  }

  /// Glowing circle decoration
  static Widget glowingCircle(Color color, double size) {
    return Container(
      width: size.w,
      height: size.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 160,
            spreadRadius: 40,
          ),
        ],
      ),
    );
  }
}
