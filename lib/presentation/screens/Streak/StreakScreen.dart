import 'dart:math' as math;
import 'dart:ui';

import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/cubit/student/streak/streak_cubit.dart';
import 'package:fluent/cubit/student/streak/streak_state.dart';
import 'package:fluent/data/models/profile_model.dart';
import 'package:fluent/data/repository/profile_repository.dart';
import 'package:fluent/helper/student_entry_navigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Finch-inspired streak celebration screen.
/// Data: profile.streak + GET /api/student/weeklyActivity
class StreakScreen extends StatelessWidget {
  const StreakScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) =>
          StreakCubit(profileRepository: ctx.read<ProfileRepository>())..load(),
      child: const _StreakView(),
    );
  }
}

class _StreakView extends StatelessWidget {
  const _StreakView();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Soft Finch-like gradient (Fluent palette)
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFE8F7FC), // soft sky tint
                  Color(0xFFB8E4F2),
                  AppColors.sky,
                  Color(0xFF7BC4D9),
                  AppColors.primary,
                ],
                stops: [0.0, 0.22, 0.45, 0.72, 1.0],
              ),
            ),
          ),

          // Ambient orbs
          Positioned(
            top: size.height * 0.08,
            right: -40,
            child: _SoftOrb(
              diameter: 160,
              color: AppColors.yellow.withOpacity(0.28),
            ),
          ),
          Positioned(
            top: size.height * 0.35,
            left: -50,
            child: _SoftOrb(
              diameter: 140,
              color: AppColors.orange.withOpacity(0.18),
            ),
          ),
          Positioned(
            bottom: size.height * 0.18,
            right: -30,
            child: _SoftOrb(
              diameter: 120,
              color: Colors.white.withOpacity(0.22),
            ),
          ),

          SafeArea(
            child: BlocBuilder<StreakCubit, StreakState>(
              builder: (context, state) {
                if (state is StreakLoading || state is StreakInitial) {
                  return const _LoadingBody();
                }

                if (state is StreakFailure && state.weeklyActivity == null) {
                  return _ErrorBody(
                    message: state.message,
                    onRetry: () => context.read<StreakCubit>().load(),
                  );
                }

                final streak = state is StreakLoaded
                    ? state.streak
                    : (state is StreakFailure ? (state.streak ?? 0) : 0);

                final weekly = state is StreakLoaded
                    ? state.weeklyActivity
                    : (state is StreakFailure
                          ? state.weeklyActivity!
                          : WeeklyActivityModel.fromJson(const {}));

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      // Top label — Finch style
                      Text(
                        'YOUR STREAK',
                        style: TextStyle(
                          fontSize: 13,
                          letterSpacing: 2.4,
                          fontWeight: FontWeight.w700,
                          color: AppColors.dark.withOpacity(0.55),
                        ),
                      ),
                      const Spacer(flex: 2),

                      // Big flame / streak badge
                      _FinchStreakBadge(streak: streak).animateEntrance(),

                      const SizedBox(height: 22),

                      Text(
                        streak > 0
                            ? (streak == 1
                                  ? 'Day 1 — you showed up!'
                                  : '$streak days in a row')
                            : 'Start your streak today',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          color: AppColors.dark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        streak > 0
                            ? 'Keep learning a little every day.\nYour consistency is building something real.'
                            : 'Complete a lesson today and light your first day.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.5,
                          height: 1.45,
                          color: AppColors.dark.withOpacity(0.62),
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const Spacer(flex: 2),

                      // Week strip — Finch day circles
                      _FinchWeekStrip(days: weekly.days),

                      const Spacer(flex: 2),

                      // Continue button
                      _FinchContinueButton(
                        onPressed: () {
                          StudentEntryNavigator.goAfterStreak(context);
                        },
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Finch-style big streak badge ─────────────────────────────

class _FinchStreakBadge extends StatelessWidget {
  final int streak;
  const _FinchStreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      height: 210,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer soft ring
          Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.28),
            ),
          ),
          Container(
            width: 178,
            height: 178,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.yellow.withOpacity(0.55),
                  AppColors.orange.withOpacity(0.35),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
          // Main card circle
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFF6D8), AppColors.yellow, AppColors.orange],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.orange.withOpacity(0.45),
                  blurRadius: 28,
                  spreadRadius: 2,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.65),
                  blurRadius: 12,
                  offset: const Offset(-4, -4),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.75),
                width: 3,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  size: 36,
                  color: AppColors.dark.withOpacity(0.85),
                ),
                const SizedBox(height: 2),
                Text(
                  '$streak',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    color: AppColors.dark,
                  ),
                ),
                Text(
                  streak == 1 ? 'day' : 'days',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.dark.withOpacity(0.65),
                  ),
                ),
              ],
            ),
          ),
          // Sparkles
          const Positioned(top: 18, right: 28, child: _Sparkle(size: 10)),
          const Positioned(top: 40, left: 22, child: _Sparkle(size: 7)),
          const Positioned(bottom: 30, right: 20, child: _Sparkle(size: 8)),
        ],
      ),
    );
  }
}

// ─── Finch week circles ───────────────────────────────────────

class _FinchWeekStrip extends StatelessWidget {
  final List<WeeklyActivityDay> days;
  const _FinchWeekStrip({required this.days});

  @override
  Widget build(BuildContext context) {
    final items = days.isEmpty
        ? List.generate(7, (i) {
            final now = DateTime.now();
            final sunday = now.subtract(Duration(days: now.weekday % 7));
            return WeeklyActivityDay(
              date: DateTime(sunday.year, sunday.month, sunday.day + i),
              completedLessons: 0,
            );
          })
        : days;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.42),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.65)),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'This week',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.dark.withOpacity(0.55),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(items.length, (index) {
              final day = items[index];
              final now = DateTime.now();
              final isToday =
                  day.date.year == now.year &&
                  day.date.month == now.month &&
                  day.date.day == now.day;
              final active = day.isActive;

              return Expanded(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 380),
                      curve: Curves.easeOutBack,
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: active
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [AppColors.yellow, AppColors.orange],
                              )
                            : null,
                        color: active
                            ? null
                            : Colors.white.withOpacity(isToday ? 0.9 : 0.55),
                        border: Border.all(
                          color: isToday
                              ? AppColors.primary
                              : (active
                                    ? Colors.white.withOpacity(0.8)
                                    : AppColors.dark.withOpacity(0.08)),
                          width: isToday ? 2.2 : 1.2,
                        ),
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: AppColors.orange.withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: active
                          ? const Icon(
                              Icons.check_rounded,
                              size: 20,
                              color: AppColors.dark,
                            )
                          : null,
                    ),
                    const SizedBox(height: 7),
                    Text(
                      day.shortLabel,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                        color: isToday
                            ? AppColors.primary
                            : AppColors.dark.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─── Continue CTA ─────────────────────────────────────────────

class _FinchContinueButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _FinchContinueButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.dark],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'Continue',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────

class _SoftOrb extends StatelessWidget {
  final double diameter;
  final Color color;
  const _SoftOrb({required this.diameter, required this.color});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  final double size;
  const _Sparkle({required this.size});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: math.pi / 4,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(2),
          boxShadow: [
            BoxShadow(color: AppColors.yellow.withOpacity(0.7), blurRadius: 6),
          ],
        ),
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 36,
        height: 36,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.dark.withOpacity(0.75),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 18),
            _FinchContinueButton(onPressed: onRetry),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => StudentEntryNavigator.goAfterStreak(context),
              child: const Text(
                'Continue anyway',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension _Entrance on Widget {
  Widget animateEntrance() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.86, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.scale(scale: value, child: child),
        );
      },
      child: this,
    );
  }
}
