import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/cubit/progress/progress_cubit.dart';
import 'package:fluent/cubit/progress/progress_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable progress card powered by ProgressCubit.
/// Call [loadCourse] / [loadLevel] from parent after creating the cubit.
class ProgressIndicatorCard extends StatelessWidget {
  final String title;
  final String scope; // 'course' | 'level'
  final int id;

  const ProgressIndicatorCard({
    super.key,
    required this.title,
    required this.scope,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProgressCubit, ProgressState>(
      builder: (context, state) {
        double? pct;
        String? error;
        bool loading = false;

        if (state is ProgressLoading &&
            state.scope == scope &&
            state.id == id) {
          loading = true;
        } else if (state is ProgressSuccess &&
            state.scope == scope &&
            state.id == id) {
          pct = state.percentage;
        } else if (state is ProgressFailure &&
            state.scope == scope &&
            state.id == id) {
          error = state.message;
        }

        return Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                ),
              ),
              SizedBox(height: 10.h),
              if (loading)
                LinearProgressIndicator(
                  backgroundColor: AppColors.sky.withOpacity(0.4),
                  color: AppColors.primary,
                )
              else if (error != null)
                Text(
                  error,
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: Colors.red.shade700,
                  ),
                )
              else ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(6.r),
                  child: LinearProgressIndicator(
                    value: ((pct ?? 0) / 100).clamp(0.0, 1.0),
                    minHeight: 8.h,
                    backgroundColor: AppColors.sky.withOpacity(0.4),
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  '${(pct ?? 0).toStringAsFixed(0)}%',
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
