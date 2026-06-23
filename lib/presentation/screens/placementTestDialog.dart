import 'dart:ui';
import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/presentation/widgets/applogo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PlacementTestDialog extends StatelessWidget {
  const PlacementTestDialog({super.key});

  @override
  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ✅ ONLY BACKGROUND BLUR (correct place)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(color: Colors.black.withOpacity(0.25)),
            ),
          ),

          // ✅ DIALOG (NO BLUR INSIDE)
          Center(
            child: Padding(
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

                  // ❌ REMOVE BackdropFilter HERE (IMPORTANT)
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
          AppLogo(size: 92),
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
          const SizedBox(height: 32),

          _GlassButton(
            label: 'Take Placement Test',
            onPressed: () {
              Navigator.of(context).pop();
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
            onPressed: () {
              Navigator.of(context).pop();
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

class _GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Gradient gradient;
  final Color textColor;
  final Color borderColor;
  final Color glowColor;

  const _GlassButton({
    required this.label,
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
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 14.5,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
