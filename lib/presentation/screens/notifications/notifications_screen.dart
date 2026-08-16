import 'dart:ui';

import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/cubit/notification/notification_cubit.dart';
import 'package:fluent/cubit/notification/notification_state.dart';
import 'package:fluent/data/models/notification_model.dart';
import 'package:fluent/helper/notification_route_resolver.dart';
import 'package:fluent/presentation/widgets/app_date_format.dart';
import 'package:fluent/presentation/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Full notifications list — premium design matching Fluent app language.
/// Supports multi-select bulk delete.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    context.read<NotificationCubit>().loadNotifications();
  }

  void _enterSelection([String? initialId]) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectionMode = true;
      _selectedIds.clear();
      if (initialId != null && initialId.isNotEmpty) {
        _selectedIds.add(initialId);
      }
    });
  }

  void _exitSelection() {
    HapticFeedback.selectionClick();
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelect(String id) {
    if (id.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _selectionMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<AppNotificationModel> list) {
    HapticFeedback.mediumImpact();
    setState(() {
      if (_selectedIds.length == list.length) {
        _selectedIds.clear();
        _selectionMode = false;
      } else {
        _selectionMode = true;
        _selectedIds
          ..clear()
          ..addAll(list.map((e) => e.id).where((id) => id.isNotEmpty));
      }
    });
  }

  Future<void> _confirmBulkDelete(BuildContext context) async {
    if (_selectedIds.isEmpty) return;

    final count = _selectedIds.length;
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (ctx) => _ConfirmDeleteDialog(count: count),
    );

    if (ok == true && context.mounted) {
      final ids = _selectedIds.toList();
      _exitSelection();
      await context.read<NotificationCubit>().deleteMultiple(ids);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff020B18),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ── Premium backdrop ──
          const _NotificationsBackdrop(),

          // ── Content ──
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),

          // ── Bulk action bar ──
          if (_selectionMode && _selectedIds.isNotEmpty)
            Positioned(
              left: 16.w,
              right: 16.w,
              bottom: 24.h,
              child: _BulkActionBar(
                count: _selectedIds.length,
                onCancel: _exitSelection,
                onDelete: () => _confirmBulkDelete(context),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return BlocBuilder<NotificationCubit, NotificationState>(
      buildWhen: (p, c) =>
          p.unreadCount != c.unreadCount ||
          p.actionLoading != c.actionLoading ||
          p.notifications != c.notifications,
      builder: (context, state) {
        return Padding(
          padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 4.h),
          child: Row(
            children: [
              _GlassIconButton(
                icon: _selectionMode
                    ? Icons.close_rounded
                    : Icons.arrow_back_ios_new_rounded,
                onTap: () {
                  if (_selectionMode) {
                    _exitSelection();
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectionMode
                          ? '${_selectedIds.length} selected'
                          : 'Notifications',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18.sp,
                        letterSpacing: 0.1,
                      ),
                    ),
                    if (!_selectionMode && state.unreadCount > 0)
                      Text(
                        '${state.unreadCount} unread',
                        style: GoogleFonts.poppins(
                          color: AppColors.orange.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                          fontSize: 11.sp,
                        ),
                      ),
                  ],
                ),
              ),
              if (!_selectionMode) ...[
                if (state.unreadCount > 0)
                  _GlassChip(
                    label: 'Mark all',
                    icon: Icons.done_all_rounded,
                    onTap: state.actionLoading
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            context.read<NotificationCubit>().markAllAsRead();
                          },
                  ),
                SizedBox(width: 8.w),
                if (state.notifications.isNotEmpty)
                  _GlassIconButton(
                    icon: Icons.checklist_rounded,
                    onTap: () => _enterSelection(),
                    tooltip: 'Select',
                  ),
              ] else ...[
                _GlassChip(
                  label: _selectedIds.length == state.notifications.length
                      ? 'Clear'
                      : 'All',
                  icon: Icons.select_all_rounded,
                  onTap: () => _selectAll(state.notifications),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    return MultiBlocListener(
      listeners: [
        BlocListener<NotificationCubit, NotificationState>(
          listenWhen: (prev, curr) =>
              curr.unreadCount > prev.unreadCount &&
              !curr.loading &&
              !curr.actionLoading,
          listener: (context, state) {
            context.read<NotificationCubit>().loadNotifications();
          },
        ),
        BlocListener<NotificationCubit, NotificationState>(
          listenWhen: (p, c) =>
              p.actionSuccess != c.actionSuccess || p.error != c.error,
          listener: (context, state) {
            if (state.actionSuccess && state.message != null) {
              _showSnack(context, state.message!, isError: false);
              context.read<NotificationCubit>().clearActionResult();
            } else if (state.error != null && state.error!.isNotEmpty) {
              _showSnack(context, state.error!, isError: true);
              context.read<NotificationCubit>().clearActionResult();
            }
          },
        ),
      ],
      child: BlocBuilder<NotificationCubit, NotificationState>(
        builder: (context, state) {
          if (state.loading && state.notifications.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.orange),
            );
          }

          if (state.error != null && state.notifications.isEmpty) {
            return _EmptyError(
              message: state.error!,
              onRetry: () =>
                  context.read<NotificationCubit>().loadNotifications(),
            );
          }

          if (state.notifications.isEmpty) {
            return const _EmptyState();
          }

          return RefreshIndicator(
            color: AppColors.orange,
            backgroundColor: AppColors.primary,
            onRefresh: () =>
                context.read<NotificationCubit>().loadNotifications(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(
                16.w,
                12.h,
                16.w,
                _selectionMode ? 100.h : 28.h,
              ),
              itemCount: state.notifications.length,
              separatorBuilder: (_, __) => SizedBox(height: 10.h),
              itemBuilder: (context, index) {
                final n = state.notifications[index];
                final selected = _selectedIds.contains(n.id);

                return _NotificationTile(
                  notification: n,
                  selectionMode: _selectionMode,
                  selected: selected,
                  onTap: () {
                    if (_selectionMode) {
                      _toggleSelect(n.id);
                      return;
                    }
                    if (!n.isRead) {
                      context.read<NotificationCubit>().markAsRead(n.id);
                    }
                    NotificationRouteResolver.open(
                      context,
                      type: n.type,
                      data: n.data,
                      fallbackTitle: n.title,
                    );
                  },
                  onLongPress: () {
                    if (!_selectionMode) {
                      _enterSelection(n.id);
                    } else {
                      _toggleSelect(n.id);
                    }
                  },
                  onDelete: () {
                    if (n.id.trim().isEmpty) return;
                    _confirmSingleDelete(context, n);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmSingleDelete(
    BuildContext context,
    AppNotificationModel n,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (ctx) => const _ConfirmDeleteDialog(count: 1),
    );
    if (ok == true && context.mounted) {
      context.read<NotificationCubit>().deleteNotification(n.id);
    }
  }

  void _showSnack(BuildContext context, String msg, {required bool isError}) {
    showAppSnackBar(
      context,
      msg,
      type: isError ? AppSnackType.error : AppSnackType.success,
    );
  }
}

// ─────────────────────────────────────────────
// Backdrop
// ─────────────────────────────────────────────

class _NotificationsBackdrop extends StatelessWidget {
  const _NotificationsBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xff020B18),
                Color(0xff072238),
                AppColors.primary,
                Color(0xff01344F),
                Color(0xff020B18),
              ],
              stops: [0.0, 0.22, 0.55, 0.8, 1.0],
            ),
          ),
        ),
        Positioned(
          top: -100.h,
          right: -60.w,
          child: _GlowBlob(color: AppColors.yellow, size: 280.w, opacity: 0.14),
        ),
        Positioned(
          top: 320.h,
          left: -80.w,
          child: _GlowBlob(color: AppColors.sky, size: 240.w, opacity: 0.10),
        ),
        Positioned(
          bottom: 80.h,
          right: -40.w,
          child: _GlowBlob(
            color: const Color(0xffB861F5),
            size: 200.w,
            opacity: 0.08,
          ),
        ),
      ],
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;

  const _GlowBlob({
    required this.color,
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(opacity * 0.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(opacity),
            blurRadius: size * 0.55,
            spreadRadius: size * 0.08,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Tile
// ─────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final AppNotificationModel notification;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;

  const _NotificationTile({
    required this.notification,
    required this.selectionMode,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    required this.onDelete,
  });

  IconData get _icon {
    switch (notification.type) {
      case AppNotificationModel.typeTopicPublished:
        return Icons.topic_rounded;
      case AppNotificationModel.typePodcastCreated:
        return Icons.podcasts_rounded;
      case AppNotificationModel.typeCourseAssigned:
        return Icons.school_rounded;
      case AppNotificationModel.typeLessonOpened:
        return Icons.play_lesson_rounded;
      case AppNotificationModel.typeLevelOpened:
        return Icons.lock_open_rounded;
      case AppNotificationModel.typeLevelException:
        return Icons.help_outline_rounded;
      case AppNotificationModel.typeLevelExceptionApproved:
        return Icons.verified_rounded;
      case AppNotificationModel.typeLevelExceptionReject:
        return Icons.cancel_outlined;
      case AppNotificationModel.typeContentDependencyChange:
        return Icons.warning_amber_rounded;
      case AppNotificationModel.typeDeleteLesson:
        return Icons.delete_outline_rounded;
      case AppNotificationModel.typeContentApproved:
        return Icons.check_circle_rounded;
      case AppNotificationModel.typeContentChangesRequested:
        return Icons.edit_note_rounded;
      case AppNotificationModel.typeContentPublished:
        return Icons.rocket_launch_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color get _accent {
    switch (notification.type) {
      case AppNotificationModel.typeContentApproved:
      case AppNotificationModel.typeContentPublished:
      case AppNotificationModel.typeLevelExceptionApproved:
      case AppNotificationModel.typeLevelOpened:
        return const Color(0xFF3DD9B6);
      case AppNotificationModel.typeContentChangesRequested:
      case AppNotificationModel.typeLevelException:
        return AppColors.lightOrange;
      case AppNotificationModel.typeContentDependencyChange:
      case AppNotificationModel.typeLevelExceptionReject:
      case AppNotificationModel.typeDeleteLesson:
        return const Color(0xFFE57373);
      case AppNotificationModel.typePodcastCreated:
        return AppColors.sky;
      case AppNotificationModel.typeCourseAssigned:
        return AppColors.yellow;
      case AppNotificationModel.typeLessonOpened:
        return const Color(0xFF7EB6FF);
      default:
        return AppColors.sky;
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final timeLabel = AppDateFormat.smart(n.createdAt) ?? '';
    final accent = _accent;
    final unread = !n.isRead;

    return Dismissible(
      key: Key(n.id),
      direction: selectionMode
          ? DismissDirection.none
          : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 22.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade900.withOpacity(0.3), Colors.red.shade800],
          ),
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 22.sp,
        ),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(18.r),
          splashColor: accent.withOpacity(0.08),
          highlightColor: accent.withOpacity(0.04),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18.r),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: selected
                    ? [
                        AppColors.orange.withOpacity(0.18),
                        AppColors.orange.withOpacity(0.08),
                      ]
                    : unread
                    ? [
                        Colors.white.withOpacity(0.10),
                        Colors.white.withOpacity(0.045),
                      ]
                    : [
                        Colors.white.withOpacity(0.055),
                        Colors.white.withOpacity(0.025),
                      ],
              ),
              border: Border.all(
                color: selected
                    ? AppColors.orange.withOpacity(0.55)
                    : unread
                    ? accent.withOpacity(0.28)
                    : Colors.white.withOpacity(0.07),
                width: selected ? 1.4 : 1,
              ),
              boxShadow: selected || unread
                  ? [
                      BoxShadow(
                        color: (selected ? AppColors.orange : accent)
                            .withOpacity(0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18.r),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Accent rail
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 3.5.w,
                        margin: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.orange
                              : unread
                              ? accent
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(12.w, 14.h, 12.w, 14.h),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon or checkbox
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: selectionMode
                                    ? _SelectionCheck(
                                        key: ValueKey('chk_$selected'),
                                        selected: selected,
                                      )
                                    : _TypeIcon(
                                        key: const ValueKey('icon'),
                                        icon: _icon,
                                        accent: accent,
                                        unread: unread,
                                      ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            n.title,
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontWeight: unread
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              fontSize: 13.5.sp,
                                              height: 1.25,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (unread && !selectionMode)
                                          Container(
                                            width: 7.w,
                                            height: 7.w,
                                            margin: EdgeInsets.only(
                                              left: 8.w,
                                              top: 3.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.orange,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.orange
                                                      .withOpacity(0.55),
                                                  blurRadius: 6,
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (n.body.isNotEmpty) ...[
                                      SizedBox(height: 4.h),
                                      Text(
                                        n.body,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white.withOpacity(
                                            unread ? 0.68 : 0.48,
                                          ),
                                          fontSize: 12.sp,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                    if (timeLabel.isNotEmpty) ...[
                                      SizedBox(height: 8.h),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.schedule_rounded,
                                            size: 11.sp,
                                            color: Colors.white30,
                                          ),
                                          SizedBox(width: 4.w),
                                          Text(
                                            timeLabel,
                                            style: GoogleFonts.poppins(
                                              color: Colors.white38,
                                              fontSize: 10.5.sp,
                                            ),
                                          ),
                                          if (n.type.isNotEmpty) ...[
                                            SizedBox(width: 8.w),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 7.w,
                                                vertical: 2.h,
                                              ),
                                              decoration: BoxDecoration(
                                                color: accent.withOpacity(0.12),
                                                borderRadius:
                                                    BorderRadius.circular(6.r),
                                                border: Border.all(
                                                  color: accent.withOpacity(
                                                    0.22,
                                                  ),
                                                ),
                                              ),
                                              child: Text(
                                                _typeLabel(n.type),
                                                style: GoogleFonts.poppins(
                                                  color: accent.withOpacity(
                                                    0.9,
                                                  ),
                                                  fontSize: 9.5.sp,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (!selectionMode)
                                Padding(
                                  padding: EdgeInsets.only(top: 2.h, left: 4.w),
                                  child: Icon(
                                    Icons.chevron_right_rounded,
                                    color: Colors.white24,
                                    size: 18.sp,
                                  ),
                                ),
                            ],
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
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case AppNotificationModel.typeTopicPublished:
        return 'Topic';
      case AppNotificationModel.typePodcastCreated:
        return 'Podcast';
      case AppNotificationModel.typeCourseAssigned:
        return 'Course';
      case AppNotificationModel.typeLessonOpened:
        return 'Lesson';
      case AppNotificationModel.typeLevelOpened:
        return 'Level';
      case AppNotificationModel.typeLevelException:
        return 'Request';
      case AppNotificationModel.typeLevelExceptionApproved:
        return 'Exception';
      case AppNotificationModel.typeLevelExceptionReject:
        return 'Rejected';
      case AppNotificationModel.typeContentDependencyChange:
        return 'Test Alert';
      case AppNotificationModel.typeDeleteLesson:
        return 'Deleted';
      case AppNotificationModel.typeContentApproved:
        return 'Approved';
      case AppNotificationModel.typeContentChangesRequested:
        return 'Changes';
      case AppNotificationModel.typeContentPublished:
        return 'Published';
      default:
        return 'Update';
    }
  }
}

class _TypeIcon extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final bool unread;

  const _TypeIcon({
    super.key,
    required this.icon,
    required this.accent,
    required this.unread,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44.w,
      height: 44.w,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withOpacity(unread ? 0.32 : 0.18),
            accent.withOpacity(unread ? 0.14 : 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: accent.withOpacity(unread ? 0.35 : 0.18)),
      ),
      child: Icon(icon, color: accent, size: 21.sp),
    );
  }
}

class _SelectionCheck extends StatelessWidget {
  final bool selected;

  const _SelectionCheck({super.key, required this.selected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 44.w,
      height: 44.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.orange : Colors.white.withOpacity(0.06),
        border: Border.all(
          color: selected ? AppColors.orange : Colors.white.withOpacity(0.25),
          width: 1.6,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppColors.orange.withOpacity(0.35),
                  blurRadius: 10,
                ),
              ]
            : [],
      ),
      child: selected
          ? Icon(Icons.check_rounded, color: Colors.white, size: 22.sp)
          : null,
    );
  }
}

// ─────────────────────────────────────────────
// Bulk action bar
// ─────────────────────────────────────────────

class _BulkActionBar extends StatelessWidget {
  final int count;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  const _BulkActionBar({
    required this.count,
    required this.onCancel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            color: const Color(0xff0A1F2E).withOpacity(0.88),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: AppColors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.poppins(
                    color: AppColors.orange,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.sp,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  count == 1 ? '1 selected' : '$count selected',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                  ),
                ),
              ),
              TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white54,
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 13.sp,
                  ),
                ),
              ),
              SizedBox(width: 4.w),
              ElevatedButton.icon(
                onPressed: onDelete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 10.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                icon: Icon(Icons.delete_outline_rounded, size: 18.sp),
                label: Text(
                  'Delete',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Confirm dialog
// ─────────────────────────────────────────────

class _ConfirmDeleteDialog extends StatelessWidget {
  final int count;

  const _ConfirmDeleteDialog({required this.count});

  @override
  Widget build(BuildContext context) {
    final title = count == 1
        ? 'Delete notification?'
        : 'Delete $count notifications?';
    final body = count == 1
        ? 'This cannot be undone.'
        : 'These $count notifications will be permanently removed.';

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: EdgeInsets.fromLTRB(22.w, 22.h, 22.w, 16.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              color: const Color(0xff0D2433).withOpacity(0.95),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52.w,
                  height: 52.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withOpacity(0.12),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                    size: 26.sp,
                  ),
                ),
                SizedBox(height: 14.h),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white60,
                    fontSize: 13.sp,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white54,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.12),
                            ),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: Text(
                          'Delete',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Small UI pieces
// ─────────────────────────────────────────────

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: Colors.white.withOpacity(0.08),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: EdgeInsets.all(10.w),
          child: Icon(icon, color: Colors.white, size: 17.sp),
        ),
      ),
    );
    if (tooltip == null) return btn;
    return Tooltip(message: tooltip!, child: btn);
  }
}

class _GlassChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _GlassChip({required this.label, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.orange.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15.sp, color: AppColors.orange),
              SizedBox(width: 5.w),
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: AppColors.orange,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(36.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96.w,
              height: 96.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.sky.withOpacity(0.18),
                    AppColors.orange.withOpacity(0.10),
                  ],
                ),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 42.sp,
                color: Colors.white54,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'No notifications yet',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'You\'ll see updates about courses,\nlessons, and reviews here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white38,
                fontSize: 12.5.sp,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _EmptyError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48.sp,
              color: Colors.redAccent,
            ),
            SizedBox(height: 12.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 13.sp,
              ),
            ),
            SizedBox(height: 18.h),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
