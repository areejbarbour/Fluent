import 'dart:async';
import 'dart:ui';
import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/constants/strings.dart';
import 'package:fluent/cubit/auth/forgot_password/forgot_password_cubit.dart';
import 'package:fluent/cubit/auth/forgot_password/forgot_password_state.dart';
import 'package:fluent/cubit/auth/verify_otp/verify_otp_cubit.dart';
import 'package:fluent/cubit/auth/verify_otp/verify_otp_state.dart';
import 'package:fluent/cubit/auth/resend_otp/resend_otp_cubit.dart';
import 'package:fluent/cubit/auth/resend_otp/resend_otp_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final FocusNode _emailFocusNode = FocusNode();
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _isOtpSent = false;
  int _remainingSeconds = 60;
  Timer? _timer;
  bool _canResend = false;

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _canResend = false;
    _remainingSeconds = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        _timer?.cancel();
      }
    });
  }

  void _onOtpChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
  }

  String _getFullOtp() {
    return _otpControllers.map((c) => c.text).join();
  }

  void _clearOtpFields() {
    for (var controller in _otpControllers) {
      controller.clear();
    }
    if (_otpFocusNodes.isNotEmpty) {
      _otpFocusNodes[0].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MultiBlocListener(
        listeners: [
          // ✅ Listener لـ ForgotPasswordCubit
          BlocListener<ForgotPasswordCubit, ForgotPasswordState>(
            listener: (context, state) {
              if (state is ForgotPasswordSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.sky,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                );
                setState(() {
                  _isOtpSent = true;
                });
                _startCountdown();
              } else if (state is ForgotPasswordFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.error),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                );
              }
            },
          ),
          // ✅ Listener لـ VerifyOtpCubit
          BlocListener<VerifyOtpCubit, VerifyOtpState>(
            listener: (context, state) {
              if (state is VerifyOtpSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.sky,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                );
                // ✅ الانتقال إلى SetNewPasswordScreen مع تمرير الإيميل
                Navigator.pushReplacementNamed(
                  context,
                  setNewPasswordRoute,
                  arguments: _emailController.text.trim(),
                );
              } else if (state is VerifyOtpFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.error),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                );
                _clearOtpFields();
              }
            },
          ),
          // ✅ Listener لـ ResendOtpCubit
          BlocListener<ResendOtpCubit, ResendOtpState>(
            listener: (context, state) {
              if (state is ResendOtpSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.sky,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                );
                _startCountdown();
              } else if (state is ResendOtpFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.error),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                );
              }
            },
          ),
        ],
        child: Stack(
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
                    _glassForgetPasswordForm(),
                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ),
          ],
        ),
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
              "FORGET PASSWORD",
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
              "Resetting your access!",
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

  Widget _glassForgetPasswordForm() {
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
                _buildEmailField(),
                SizedBox(height: 20.h),
                Text(
                  "Check your email for a verification code.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 30.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    6,
                    (index) => _buildSingleOtpField(index, enabled: _isOtpSent),
                  ),
                ),
                // SizedBox(height: 0.h),
                GestureDetector(
                  onTap: _canResend && _isOtpSent
                      ? () {
                          context.read<ResendOtpCubit>().resendOtp(
                            email: _emailController.text.trim(),
                            type: OtpType.forgotPassword,
                          );
                        }
                      : null,
                  child: Text(
                    "Resend Code",
                    style: GoogleFonts.poppins(
                      color: (_canResend && _isOtpSent)
                          ? AppColors.yellow
                          : Colors.white.withOpacity(0.4),
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  _isOtpSent
                      ? (_canResend
                            ? "You can resend now"
                            : "Resend in 0:${_remainingSeconds.toString().padLeft(2, '0')}")
                      : "",
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 10.h),
                _buildResetButton(),
                SizedBox(height: 24.h),
                _backToLoginLink(),
                SizedBox(height: 10.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return Focus(
      key: const ValueKey("ForgetEmailField"),
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
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isOtpSent, // ✅ تعطيل الحقل بعد إرسال OTP
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 15.sp,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(.14),
                    hintText: "Email Address",
                    hintStyle: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.65),
                    ),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: Colors.white.withOpacity(0.85),
                      size: 22.sp,
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
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

  Widget _buildSingleOtpField(int index, {bool enabled = true}) {
    return Focus(
      key: ValueKey("OtpField_$index"),
      child: Builder(
        builder: (context) {
          final bool hasFocus = Focus.of(context).hasFocus;
          return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 45.w,
                height: 72.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: hasFocus && enabled
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
                  controller: _otpControllers[index],
                  focusNode: _otpFocusNodes[index],
                  enabled: enabled,
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
                        color: enabled
                            ? AppColors.sky.withOpacity(0.45)
                            : Colors.white.withOpacity(0.2),
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
                onInit: (controller) => hasFocus && enabled
                    ? controller.stop()
                    : controller.repeat(reverse: true),
                onPlay: (controller) => hasFocus && enabled
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

  Widget _buildResetButton() {
    return BlocBuilder<ForgotPasswordCubit, ForgotPasswordState>(
      builder: (context, forgotState) {
        return BlocBuilder<VerifyOtpCubit, VerifyOtpState>(
          builder: (context, verifyState) {
            final isLoading =
                forgotState is ForgotPasswordLoading ||
                verifyState is VerifyOtpLoading;
            final buttonText = _isOtpSent ? "VERIFY CODE" : "SEND OTP CODE";

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
                onTap: isLoading
                    ? null
                    : () {
                        if (_isOtpSent) {
                          // ✅ التحقق من OTP
                          String otpCode = _getFullOtp();
                          if (otpCode.length == 6) {
                            context.read<VerifyOtpCubit>().verifyOtp(
                              email: _emailController.text.trim(),
                              otp: otpCode,
                              type: OtpType.forgotPassword,
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please enter the complete 6-digit code',
                                ),
                                backgroundColor: Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(10),
                                  ),
                                ),
                              ),
                            );
                          }
                        } else {
                          // ✅ إرسال OTP
                          if (_formKey.currentState!.validate()) {
                            context.read<ForgotPasswordCubit>().forgotPassword(
                              email: _emailController.text.trim(),
                            );
                          }
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
                    child: isLoading
                        ? SizedBox(
                            width: 24.w,
                            height: 24.w,
                            child: CircularProgressIndicator(
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.black,
                              ),
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            buttonText,
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
            );
          },
        );
      },
    );
  }

  Widget _backToLoginLink() {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacementNamed(context, loginRoute);
      },
      child: Text.rich(
        TextSpan(
          text: "Return to? ",
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14.sp),
          children: [
            TextSpan(
              text: "Log In",
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
