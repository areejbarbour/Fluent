import 'dart:ui';
import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/constants/strings.dart';
import 'package:fluent/helper/student_entry_navigator.dart';
import 'package:fluent/data/models/level_model.dart';
import 'package:fluent/data/repository/level_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/presentation/screens/placement/placement_test_screen.dart';
import 'package:fluent/presentation/widgets/applogo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

/// First-login placement choice — clean product UI only (no server jargon).
/// If the student already completed placement / has levels → go home immediately.
class PlacementTestDialog extends StatefulWidget {
  const PlacementTestDialog({super.key});

  @override
  State<PlacementTestDialog> createState() => _PlacementTestDialogState();
}

class _PlacementTestDialogState extends State<PlacementTestDialog> {
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _gate();
  }

  Future<void> _gate() async {
    try {
      final alreadyPlaced = await StudentEntryNavigator.hasCompletedPlacement(
        context,
      );
      if (!mounted) return;
      if (alreadyPlaced) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(studentHomeRoute, (route) => false);
        return;
      }
    } catch (_) {
      // fall through to dialog
    }
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Material(
        color: Colors.black54,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.yellow),
        ),
      );
    }

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(color: Colors.black.withOpacity(0.25)),
            ),
          ),
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
                  child: const _DialogContent(),
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
  const _DialogContent();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppLogo(size: 92)
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(begin: const Offset(0.8, 0.8)),
          const SizedBox(height: 28),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppColors.sky, AppColors.yellow],
            ).createShader(bounds),
            child: Text(
              'Find Your Level',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                height: 1.3,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Take a short test to start at the right level,\nor begin from Level 1.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
              height: 1.55,
              fontWeight: FontWeight.w400,
              color: AppColors.lightOrange.withOpacity(0.95),
            ),
          ),
          const SizedBox(height: 32),
          _GlassButton(
            label: 'Take Placement Test',
            icon: Icons.rocket_launch_rounded,
            onPressed: () {
              Navigator.of(context).pop();
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
            onPressed: () async {
              await StudentEntryNavigator.markSkipPlacement();
              await StudentEntryNavigator.markOnboarded();
              if (!context.mounted) return;
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
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
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
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 14.5,
                  letterSpacing: 0.3,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
