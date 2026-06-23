import 'package:flutter/material.dart';
import 'package:fluent/constants/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 90});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.sky.withOpacity(0.45),
            blurRadius: 60,
            spreadRadius: 10,
          ),
          BoxShadow(
            color: AppColors.yellow.withOpacity(0.25),
            blurRadius: 70,
            spreadRadius: 12,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // outer ring
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.yellow.withOpacity(0.25),
                width: 1.5,
              ),
            ),
          ),

          // inner ring
          Container(
            width: size - 8,
            height: size - 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.sky.withOpacity(0.25),
                width: 1.2,
              ),
            ),
          ),

          // image
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: Image.asset(
              "assets/images/onboarding/register_logo.png",
              width: size - 18,
              height: size - 18,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}
