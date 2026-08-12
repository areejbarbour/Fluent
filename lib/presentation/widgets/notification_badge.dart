import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/cubit/notification/notification_cubit.dart';
import 'package:fluent/cubit/notification/notification_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Simple unread-count badge for AppBar / bottom nav.
/// Usage:
///   BlocProvider.value(
///     value: context.read<NotificationCubit>()..loadUnreadCount(),
///     child: NotificationBadge(onTap: () => openNotificationsPage()),
///   )
class NotificationBadge extends StatelessWidget {
  final VoidCallback? onTap;
  final Color iconColor;
  final double iconSize;

  const NotificationBadge({
    super.key,
    this.onTap,
    this.iconColor = Colors.white,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationCubit, NotificationState>(
      buildWhen: (prev, curr) => prev.unreadCount != curr.unreadCount,
      builder: (context, state) {
        final count = state.unreadCount;
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsets.all(6.w),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.notifications_outlined,
                  color: iconColor,
                  size: iconSize.sp,
                ),
                if (count > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: count > 9 ? 5.w : 4.w,
                        vertical: 1.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: AppColors.dark, width: 1.5),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 16.w,
                        minHeight: 16.w,
                      ),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
