import 'dart:math' as math;

import 'package:fluent/constants/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppBackdrop extends StatelessWidget {
  final ValueListenable<double>? scrollOffset;
  final int starCount;
  final int seed;

  const AppBackdrop({
    super.key,
    this.scrollOffset,
    this.starCount = 40,
    this.seed = 7,
  });

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
        _Glow(
          top: -120.h,
          right: -80.w,
          color: AppColors.yellow,
          size: 300.w,
          factor: 0.18,
          duration: 5500,
          endOffset: const Offset(-15, 10),
          scrollOffset: scrollOffset,
        ),
        _Glow(
          top: 400.h,
          left: -100.w,
          color: AppColors.sky,
          size: 260.w,
          factor: 0.12,
          duration: 6500,
          endOffset: const Offset(20, 15),
          scrollOffset: scrollOffset,
        ),
        _Glow(
          top: 780.h,
          right: -60.w,
          color: const Color(0xffB861F5),
          size: 220.w,
          factor: 0.09,
          duration: 7000,
          endOffset: const Offset(-10, -8),
          scrollOffset: scrollOffset,
        ),
        _TwinklingStars(count: starCount, seed: seed),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final Color color;
  final double size;
  final double factor;
  final int duration;
  final Offset endOffset;
  final ValueListenable<double>? scrollOffset;

  const _Glow({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.color,
    required this.size,
    required this.factor,
    required this.duration,
    required this.endOffset,
    required this.scrollOffset,
  });

  @override
  Widget build(BuildContext context) {
    final glow =
        Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.12),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.32),
                    blurRadius: 160,
                    spreadRadius: 40,
                  ),
                ],
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .move(
              begin: Offset.zero,
              end: endOffset,
              duration: duration.ms,
              curve: Curves.easeInOut,
            );

    if (scrollOffset == null) {
      return Positioned(top: top, bottom: bottom, left: left, right: right, child: glow);
    }

    return ValueListenableBuilder<double>(
      valueListenable: scrollOffset!,
      builder: (context, offset, child) {
        final shift = (offset * factor).clamp(-40.0, 40.0);
        return Positioned(
          top: top == null ? null : top! + shift,
          bottom: bottom == null ? null : bottom! - shift,
          left: left,
          right: right,
          child: glow,
        );
      },
    );
  }
}

class _TwinklingStars extends StatelessWidget {
  final int count;
  final int seed;
  const _TwinklingStars({this.count = 40, this.seed = 7});

  @override
  Widget build(BuildContext context) {
    final rng = math.Random(seed);
    return IgnorePointer(
      child: Stack(
        children: List.generate(count, (i) {
          final left = rng.nextDouble();
          final top = rng.nextDouble();
          final size = rng.nextDouble() * 2 + 1;
          final delay = rng.nextInt(3000);
          final duration = 1500 + rng.nextInt(2500);
          final maxOpacity = rng.nextDouble() * 0.6 + 0.3;
          final hasGlow = rng.nextBool();

          return Positioned(
            left: left * 1.sw,
            top: top * 1.sh,
            child:
                Container(
                      width: size.w,
                      height: size.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: hasGlow
                            ? [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.7),
                                  blurRadius: 4,
                                  spreadRadius: 0.5,
                                ),
                              ]
                            : null,
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fade(
                      begin: 0,
                      end: maxOpacity,
                      duration: duration.ms,
                      delay: delay.ms,
                    )
                    .then()
                    .fade(begin: maxOpacity, end: 0, duration: duration.ms),
          );
        }),
      ),
    );
  }
}