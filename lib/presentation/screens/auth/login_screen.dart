import 'dart:ui';
import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/constants/strings.dart'; // تم إضافة هذا الاستيراد
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.dark, AppColors.primary, AppColors.sky],
              ),
            ),
          ),
          Positioned(
            top: -140.h,
            left: -90.w,
            child: _glowingCircle(AppColors.yellow, 320.w)
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .move(
                  begin: Offset.zero,
                  end: const Offset(15, 10),
                  duration: 5000.ms,
                  curve: Curves.easeInOut,
                ),
          ),
          Positioned(
            bottom: -160.h,
            right: -110.w,
            child: _glowingCircle(AppColors.sky, 380.w)
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .move(
                  begin: Offset.zero,
                  end: const Offset(-20, -15),
                  duration: 6000.ms,
                  curve: Curves.easeInOut,
                ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  SizedBox(height: 20.h),
                  _buildTopBar(),
                  SizedBox(height: 30.h),
                  _buildLogoAndTitle(),
                  SizedBox(height: 40.h),
                  _glassLoginForm(),
                  SizedBox(height: 24.h),
                  _googleButton(),
                  SizedBox(height: 28.h),
                  _signUpLink(),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowingCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 160,
            spreadRadius: 40,
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.15),
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20.sp,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoAndTitle() {
    final double logoSize = 200.w;
    final double innerLogoDiameter = logoSize * 0.92;

    return Column(
      children: [
        Container(
              width: logoSize,
              height: logoSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.sky.withOpacity(0.45),
                    blurRadius: 60,
                    spreadRadius: 8,
                  ),
                  BoxShadow(
                    color: AppColors.yellow.withOpacity(0.35),
                    blurRadius: 70,
                    spreadRadius: 12,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                        width: logoSize,
                        height: logoSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.yellow.withOpacity(0.35),
                            width: 1.8,
                          ),
                        ),
                      )
                      .animate(onPlay: (controller) => controller.repeat())
                      .rotate(duration: 10.seconds),
                  Container(
                        width: logoSize - 10.w,
                        height: logoSize - 10.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.sky.withOpacity(0.25),
                            width: 1.2,
                          ),
                        ),
                      )
                      .animate(onPlay: (controller) => controller.repeat())
                      .rotate(duration: 6.seconds, begin: 1, end: 0),
                  Container(
                        width: logoSize - 24.w,
                        height: logoSize - 24.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.18),
                              Colors.white.withOpacity(0.03),
                            ],
                          ),
                        ),
                        child: Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(100.r),
                            child: SizedBox(
                              width: innerLogoDiameter,
                              height: innerLogoDiameter,
                              child: Opacity(
                                opacity: 0.98,
                                child: Image.asset(
                                  "assets/images/onboarding/register_logo.png",
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                      .animate(
                        onPlay: (controller) =>
                            controller.repeat(reverse: true),
                      )
                      .scale(
                        begin: const Offset(0.96, 0.96),
                        end: const Offset(1.04, 1.04),
                        duration: 2500.ms,
                        curve: Curves.easeInOut,
                      ),
                ],
              ),
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: false))
            .fadeIn(duration: 1000.ms)
            .shimmer(
              duration: 3500.ms,
              color: Colors.white.withOpacity(0.45),
              delay: 1000.ms,
            ),

        SizedBox(height: 35.h),
        Text(
              "LOG IN TO YOUR ACCOUNT ",
              textAlign: TextAlign.center,
              style: GoogleFonts.cinzelDecorative(
                color: Colors.white,
                fontSize: 26.sp,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.5,
                fontFeatures: [
                  FontFeature.stylisticSet(1),
                  const FontFeature('swsh'),
                  const FontFeature('aalt'),
                ],
                shadows: [
                  Shadow(color: AppColors.sky.withOpacity(0.9), blurRadius: 15),
                  Shadow(
                    color: AppColors.yellow.withOpacity(0.6),
                    blurRadius: 30,
                  ),
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
            )
            .animate(onPlay: (controller) => controller.repeat())
            .fadeIn(duration: 800.ms)
            .moveY(
              begin: 15,
              end: 0,
              duration: 800.ms,
              curve: Curves.easeOutCubic,
            )
            .shimmer(
              duration: 4000.ms,
              color: AppColors.yellow.withOpacity(0.4),
              delay: 2000.ms,
            ),

        SizedBox(height: 12.h),
        Text(
              "Welcome back! Sign in to continue your journey",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.75),
                fontSize: 13.sp,
                height: 1.5,
              ),
            )
            .animate()
            .fadeIn(delay: 600.ms, duration: 600.ms)
            .moveY(begin: 10, end: 0, duration: 600.ms, curve: Curves.easeOut),
      ],
    );
  }

  Widget _glassLoginForm() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(35.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          padding: EdgeInsets.all(22.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(35.r),
            color: Colors.white.withOpacity(.12),
            border: Border.all(color: Colors.white.withOpacity(.25)),
            boxShadow: [
              BoxShadow(color: AppColors.sky.withOpacity(.25), blurRadius: 30),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildInputField("Email Address", Icons.email_outlined),
                SizedBox(height: 15.h),
                _buildInputField(
                  "Password",
                  Icons.lock_outline,
                  isPassword: true,
                ),
                SizedBox(height: 14.h),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      // الانتقال إلى شاشة نسيت كلمة المرور
                      Navigator.pushNamed(context, forgotPasswordRoute);
                    },
                    child: Text(
                      "Forgot Password?",
                      style: GoogleFonts.poppins(
                        color: AppColors.yellow,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 25.h),
                _buildLoginButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    String hint,
    IconData icon, {
    bool isPassword = false,
  }) {
    return Focus(
      key: ValueKey(hint),
      child: Builder(
        builder: (context) {
          final bool hasFocus = Focus.of(context).hasFocus;
          return TextFormField(
                obscureText: isPassword ? _obscurePassword : false,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 15.sp,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(.14),
                  hintText: hint,
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.65),
                  ),
                  prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.85)),
                  suffixIcon: isPassword
                      ? IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white.withOpacity(0.85),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        )
                      : null,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 18.h,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.r),
                    borderSide: const BorderSide(
                      color: AppColors.sky,
                      width: 1.8,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.r),
                    borderSide: const BorderSide(
                      color: AppColors.sky,
                      width: 2.2,
                    ),
                  ),
                ),
              )
              .animate(
                onInit: (controller) => hasFocus
                    ? controller.stop()
                    : controller.repeat(reverse: true),
                onPlay: (controller) => hasFocus
                    ? controller.stop()
                    : controller.repeat(reverse: true),
              )
              .scale(
                begin: const Offset(0.98, 0.98),
                end: const Offset(1.02, 1.02),
                duration: 1800.ms,
                curve: Curves.easeInOut,
              );
        },
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
          padding: EdgeInsets.all(4.r),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.r),
            color: AppColors.yellow,
            border: Border.all(
              color: AppColors.yellow.withOpacity(0.4),
              width: 2,
            ),
          ),
          child: InkWell(
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                streakRoute,
                (route) => false,
              );
            },
            borderRadius: BorderRadius.circular(20.r),
            child: Ink(
              width: double.infinity,
              height: 62.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                gradient: const LinearGradient(
                  colors: [AppColors.orange, AppColors.yellow],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.yellow.withOpacity(.5),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  "LOG IN",
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 23.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.5))
        .scale(
          end: const Offset(1.02, 1.02),
          duration: 1200.ms,
          curve: Curves.easeInOut,
        );
  }

  Widget _googleButton() {
    return InkWell(
      onTap: () {
        // الانتقال إلى الشاشة الرئيسية
        Navigator.pushNamedAndRemoveUntil(context, homeRoute, (route) => false);
      },
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        width: double.infinity,
        height: 62.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: AppColors.orange.withOpacity(0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.yellow.withOpacity(.25),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/images/onboarding/google.png", width: 24.w),
            SizedBox(width: 12.w),
            Text(
              "CONTINUE WITH GOOGLE",
              style: GoogleFonts.poppins(
                color: Colors.black87,
                fontWeight: FontWeight.w700,
                fontSize: 14.sp,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _signUpLink() {
    return GestureDetector(
      onTap: () {
        // الانتقال إلى شاشة إنشاء حساب جديد
        Navigator.pushNamed(context, registerRoute);
      },
      child: Text.rich(
        TextSpan(
          text: "Don't have an account? ",
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14.sp),
          children: [
            TextSpan(
              text: "Sign Up",
              style: GoogleFonts.poppins(
                color: AppColors.yellow,
                fontWeight: FontWeight.w700,
                fontSize: 17.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
