import 'dart:ui';
import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/constants/strings.dart'; // تم إضافة هذا الاستيراد
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onOtpChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
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
                  _glassOtpForm(),
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
              "VERIFY YOUR IDENTITY",
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
              "Enter the OTP code sent to your email",
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

  Widget _glassOtpForm() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(35.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
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
                SizedBox(height: 10.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    6,
                    (index) => _buildSingleOtpField(index),
                  ),
                ),
                SizedBox(height: 35.h),
                _buildConfirmButton(),
                SizedBox(height: 24.h),
                GestureDetector(
                  onTap: () {
                    // يمكن إضافة كود إعادة إرسال الإيميل هنا
                  },
                  child: Text(
                    "Resend Code?",
                    style: GoogleFonts.poppins(
                      color: AppColors.yellow,
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  "Resend in 0:59",
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 10.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSingleOtpField(int index) {
    return Focus(
      key: ValueKey("OtpVerifyField_$index"),
      child: Builder(
        builder: (context) {
          final bool hasFocus = Focus.of(context).hasFocus;
          return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 46.w,
                height: 68.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: hasFocus
                      ? [
                          BoxShadow(
                            color: AppColors.sky.withOpacity(0.6),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: AppColors.sky.withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 6,
                          ),
                        ]
                      : [],
                ),
                child: TextFormField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  onChanged: (value) => _onOtpChanged(value, index),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w800,
                  ),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(1),
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(.14),
                    contentPadding: EdgeInsets.zero,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      borderSide: BorderSide(
                        color: AppColors.sky.withOpacity(0.45),
                        width: 1.8,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.r),
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
                duration: 1600.ms,
                curve: Curves.easeInOut,
              );
        },
      ),
    );
  }

  Widget _buildConfirmButton() {
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
              String otpCode = _controllers.map((c) => c.text).join();
              if (otpCode.length == 6) {
                // الانتقال إلى شاشة تعيين كلمة مرور جديدة
                Navigator.pushReplacementNamed(context, setNewPasswordRoute);
              }
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
                  "CONFIRM CODE",
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 21.sp,
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
}
