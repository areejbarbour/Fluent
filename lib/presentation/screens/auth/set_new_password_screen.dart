import 'dart:ui';
import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/constants/strings.dart'; // تم إضافة هذا الاستيراد
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class SetNewPasswordScreen extends StatefulWidget {
  const SetNewPasswordScreen({super.key});

  @override
  State<SetNewPasswordScreen> createState() => _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends State<SetNewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FocusNode _newPasswordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _newPasswordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

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
                  _glassSetPasswordForm(),
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
              "SET NEW PASSWORD",
              textAlign: TextAlign.center,
              style: GoogleFonts.cinzelDecorative(
                color: Colors.white,
                fontSize: 26.sp,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.5,
                fontFeatures: [
                  FontFeature.stylisticSet(1),
                  FontFeature('swsh'),
                  FontFeature('aalt'),
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
              "Secure your account now!",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.8),
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

  Widget _glassSetPasswordForm() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(35.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 30.h),
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
                _buildPasswordField(
                  controller: _newPasswordController,
                  focusNode: _newPasswordFocusNode,
                  hint: "New Password",
                  isObscured: _obscureNewPassword,
                  onToggle: () => setState(
                    () => _obscureNewPassword = !_obscureNewPassword,
                  ),
                ),
                SizedBox(height: 20.h),
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  focusNode: _confirmPasswordFocusNode,
                  hint: "Confirm New Password",
                  isObscured: _obscureConfirmPassword,
                  onToggle: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  ),
                ),
                SizedBox(height: 35.h),
                _buildConfirmButton(),
                SizedBox(height: 24.h),
                _backToLoginLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required bool isObscured,
    required VoidCallback onToggle,
  }) {
    return Focus(
      child: Builder(
        builder: (context) {
          final bool hasFocus = Focus.of(context).hasFocus;
          return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: hasFocus
                      ? [
                          BoxShadow(
                            color: AppColors.sky.withOpacity(0.5),
                            blurRadius: 14,
                            spreadRadius: 1,
                          ),
                          BoxShadow(
                            color: AppColors.sky.withOpacity(0.25),
                            blurRadius: 25,
                            spreadRadius: 4,
                          ),
                        ]
                      : [],
                ),
                child: TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  obscureText: isObscured,
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
                    prefixIcon: Icon(
                      Icons.lock_outline_rounded,
                      color: Colors.white.withOpacity(0.85),
                      size: 22.sp,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isObscured
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.white.withOpacity(0.6),
                        size: 20.sp,
                      ),
                      onPressed: onToggle,
                    ),
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

  Widget _buildConfirmButton() {
    return Container(
      width: double.infinity,
      height: 62.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: const LinearGradient(
          colors: [AppColors.orange, AppColors.yellow],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.orange.withOpacity(.5),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            // الانتقال إلى شاشة تسجيل الدخول مع مسح كامل للسجل
            Navigator.pushNamedAndRemoveUntil(
              context,
              loginRoute,
              (route) => false,
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
        ),
        child: Center(
          child: Text(
            "CONFIRM PASSWORD",
            style: GoogleFonts.poppins(
              color: AppColors.dark,
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _backToLoginLink() {
    return GestureDetector(
      onTap: () {
        // العودة إلى شاشة تسجيل الدخول مع مسح كامل للسجل
        Navigator.pushNamedAndRemoveUntil(
          context,
          loginRoute,
          (route) => false,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 8.w),
          Text(
            "Return to log in",
            style: GoogleFonts.poppins(
              color: AppColors.yellow,
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          Icon(
            Icons.arrow_forward_rounded,
            color: AppColors.yellow,
            size: 18.sp,
          ),
        ],
      ),
    );
  }
}
