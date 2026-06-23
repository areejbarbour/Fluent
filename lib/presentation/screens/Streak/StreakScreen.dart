import 'dart:ui';
import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/presentation/screens/placementTestDialog.dart';
import 'package:fluent/presentation/widgets/applogo.dart';
import 'package:flutter/material.dart';

class StreakScreen extends StatelessWidget {
  const StreakScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/background/stars.png', fit: BoxFit.cover),

          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.lightOrange,
                  AppColors.primary.withOpacity(0.58),
                  AppColors.dark.withOpacity(0.96),
                ],
              ),
            ),
          ),

          // Soft ambient glows
          Positioned(
            top: -60,
            left: -50,
            child: _GlowBlob(size: 180, color: AppColors.sky.withOpacity(0.12)),
          ),
          Positioned(
            bottom: 120,
            right: -40,
            child: _GlowBlob(
              size: 160,
              color: AppColors.orange.withOpacity(0.12),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 18),

                  const AppLogo(size: 90),
                  const SizedBox(height: 18),

                  const Text(
                    'STREAK!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8,
                      color: AppColors.sky,
                      shadows: [
                        Shadow(color: AppColors.yellow, blurRadius: 22),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  const Text(
                    'Your progress is looking cosmic!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 15,
                      height: 1.35,
                      color: AppColors.lightOrange,
                    ),
                  ),

                  const Spacer(flex: 2),

                  const CentralDiamond(days: '42'),

                  const Spacer(flex: 2),

                  const _SectionLabel(text: 'THIS WEEK'),
                  const SizedBox(height: 14),

                  const WeeklyProgress(),

                  const Spacer(flex: 1),

                  _ActionButton(
                    label: 'SEE YOUR JOURNEY SO FAR',
                    onPressed: () {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return const PlacementTestDialog();
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CentralDiamond extends StatelessWidget {
  final String days;
  const CentralDiamond({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer rings
        Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.sky.withOpacity(0.08),
              width: 1,
            ),
          ),
        ),
        Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.orange.withOpacity(0.10),
              width: 1,
            ),
          ),
        ),

        // Main glass shape
        ClipPath(
          clipper: HexagonClipper(),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              width: 230,
              height: 260,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.sky.withOpacity(0.38),
                    AppColors.dark.withOpacity(0.58),
                  ],
                ),
                border: Border.all(
                  color: AppColors.sky.withOpacity(0.22),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.sky.withOpacity(0.10),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.sky.withOpacity(0.0),
                            AppColors.sky.withOpacity(0.30),
                            AppColors.sky.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.orange.withOpacity(0.0),
                            AppColors.orange.withOpacity(0.25),
                            AppColors.orange.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [AppColors.sky, AppColors.yellow],
                          ).createShader(bounds),
                          child: Text(
                            days,
                            style: const TextStyle(
                              fontSize: 76,
                              fontWeight: FontWeight.w900,
                              height: 1,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'DAYS',
                          style: TextStyle(
                            fontSize: 22,
                            letterSpacing: 7,
                            fontWeight: FontWeight.w700,
                            color: AppColors.lightOrange,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: 42,
                          height: 1,
                          color: AppColors.yellow.withOpacity(0.55),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'CONSECUTIVE\nDAILY LOG-INS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10.5,
                            height: 1.5,
                            letterSpacing: 1.3,
                            color: AppColors.sky,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class WeeklyProgress extends StatelessWidget {
  const WeeklyProgress({super.key});

  @override
  Widget build(BuildContext context) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', ''];
    final totalDays = days.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        // العرض المتاح بالكامل
        final availableWidth = constraints.maxWidth;

        // نطرح المسافات بين العناصر: (عدد العناصر - 1) × 8
        final totalSpacing = (totalDays - 1) * 8.0;
        // عرض كل مربع
        final boxWidth = (availableWidth - totalSpacing) / totalDays;
        // ارتفاع المربع (نسبة 1.14 تقريباً)
        final boxHeight = boxWidth * 1.14;

        // حجم الخط يتناسب مع حجم المربع
        final fontSize = boxWidth * 0.33;
        // حجم الخط للـ label (M, T, W...)
        final labelFontSize = boxWidth * 0.33;
        // عرض الخط الفاصل بين الأيام
        final separatorWidth = boxWidth * 0.24;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(totalDays, (index) {
            final day = days[index];
            final isLast = day.isEmpty;
            final isActive = index <= 4; // غيّريها حسب التقدم الحقيقي

            return Padding(
              padding: EdgeInsets.only(right: index == totalDays - 1 ? 0 : 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: boxWidth,
                    height: boxHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(boxWidth * 0.33),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isLast
                            ? [
                                AppColors.dark.withOpacity(0.72),
                                AppColors.primary.withOpacity(0.45),
                              ]
                            : isActive
                            ? [
                                AppColors.sky.withOpacity(0.38),
                                AppColors.primary.withOpacity(0.48),
                              ]
                            : [
                                AppColors.sky.withOpacity(0.28),
                                AppColors.dark.withOpacity(0.58),
                              ],
                      ),
                      border: Border.all(
                        color: isActive
                            ? AppColors.sky.withOpacity(0.30)
                            : AppColors.sky.withOpacity(0.16),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isActive
                              ? AppColors.sky.withOpacity(0.12)
                              : Colors.transparent,
                          blurRadius: boxHeight * 0.37,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          color: AppColors.sky.withOpacity(isLast ? 0.45 : 1),
                          fontWeight: FontWeight.w800,
                          fontSize: labelFontSize,
                        ),
                      ),
                    ),
                  ),
                  if (index != totalDays - 1)
                    Container(
                      width: separatorWidth,
                      height: 2,
                      margin: EdgeInsets.only(top: boxHeight * 0.21),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.sky.withOpacity(0.15),
                      ),
                    ),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.lightOrange,
        fontSize: 12,
        letterSpacing: 4,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.55),
                AppColors.dark.withOpacity(0.78),
              ],
            ),
            border: Border.all(
              color: AppColors.sky.withOpacity(0.18),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.sky.withOpacity(0.08),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.auto_graph_rounded,
                size: 18,
                color: AppColors.sky,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.sky,
                    fontSize: 12,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
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

class _GlowBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width * 0.5, 0);
    path.lineTo(size.width, size.height * 0.25);
    path.lineTo(size.width, size.height * 0.75);
    path.lineTo(size.width * 0.5, size.height);
    path.lineTo(0, size.height * 0.75);
    path.lineTo(0, size.height * 0.25);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
