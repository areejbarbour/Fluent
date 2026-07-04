import 'dart:ui';
import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/constants/strings.dart';
import 'package:fluent/data/models/placement_question_model.dart';
import 'package:fluent/presentation/screens/placement/placement_test_screen.dart';
import 'package:fluent/presentation/widgets/applogo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// ديالوج الترحيب — يظهر للمستخدم بعد التسجيل لأول مرة
/// يعرض خيارين: بدء اختبار تحديد المستوى أو البدء من المستوى الأول
class PlacementTestDialog extends StatelessWidget {
  const PlacementTestDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // خلفية معتمة + blur
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(color: Colors.black.withOpacity(0.25)),
            ),
          ),

          // الديالوج
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.sky.withOpacity(0.28),
                        AppColors.dark.withOpacity(0.72),
                      ],
                    ),
                    border: Border.all(
                      color: AppColors.sky.withOpacity(0.22),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.sky.withOpacity(0.12),
                        blurRadius: 40,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 28,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: _DialogContent(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppLogo(size: 92)
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(begin: const Offset(0.8, 0.8)),
          const SizedBox(height: 28),

          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [AppColors.sky, AppColors.yellow],
            ).createShader(bounds),
            child: const Text(
              'Take a Placement Test',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                height: 1.3,
                color: Colors.white,
                shadows: [
                  Shadow(color: AppColors.sky, blurRadius: 15),
                  Shadow(
                    color: AppColors.sky,
                    blurRadius: 30,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Assess your skills to skip levels,\nor start directly from Level 1.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15.5,
              height: 1.6,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.3,
              color: AppColors.lightOrange,
            ),
          ),
          const SizedBox(height: 24),

          // ملخص قصير للاختبار
          Center(
            child: _MiniInfo(
              icon: Icons.quiz_rounded,
              text: '${kPlacementQuestions.length} questions in 15 minutes',
            ),
          ),
          const SizedBox(height: 28),

          _GlassButton(
            label: 'Take Placement Test',
            icon: Icons.rocket_launch_rounded,
            onPressed: () {
              Navigator.of(context).pop(); // إغلاق الديالوج
              // فتح شاشة الاختبار الكاملة
              Navigator.of(context).push(
                PageRouteBuilder(
                  opaque: true,
                  transitionDuration: const Duration(milliseconds: 400),
                  pageBuilder: (_, __, ___) =>
                      const PlacementTestScreen(showIntro: true),
                  transitionsBuilder: (_, anim, __, child) {
                    return FadeTransition(
                      opacity: CurvedAnimation(
                        parent: anim,
                        curve: Curves.easeOut,
                      ),
                      child: SlideTransition(
                        position:
                            Tween<Offset>(
                              begin: const Offset(0, 0.08),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: anim,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                        child: child,
                      ),
                    );
                  },
                ),
              );
            },
            gradient: LinearGradient(
              colors: [
                AppColors.orange.withOpacity(0.90),
                AppColors.lightOrange.withOpacity(0.80),
              ],
            ),
            textColor: AppColors.dark,
            borderColor: AppColors.yellow.withOpacity(0.6),
            glowColor: AppColors.orange,
          ),
          const SizedBox(height: 14),

          _GlassButton(
            label: 'Start at Level 1',
            icon: Icons.play_arrow_rounded,
            onPressed: () {
              Navigator.of(context).pop();
              // التوجه لصفحة الطالب الرئيسية (مع مسح الـ stack)
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(studentHomeRoute, (route) => false);
            },
            gradient: LinearGradient(
              colors: [
                AppColors.sky.withOpacity(0.50),
                AppColors.primary.withOpacity(0.60),
              ],
            ),
            textColor: AppColors.sky,
            borderColor: AppColors.sky.withOpacity(0.40),
            glowColor: AppColors.sky,
          ),
          const SizedBox(height: 22),

          Text(
            '* You can change this later in Settings.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.0,
              color: AppColors.sky.withOpacity(0.7),
              height: 1.5,
              letterSpacing: 0.3,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MiniInfo({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.sky.withOpacity(0.10),
        border: Border.all(color: AppColors.sky.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.sky, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.sky,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Gradient gradient;
  final Color textColor;
  final Color borderColor;
  final Color glowColor;

  const _GlassButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.gradient,
    required this.textColor,
    required this.borderColor,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: gradient,
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: glowColor.withOpacity(0.25),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14.5,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
