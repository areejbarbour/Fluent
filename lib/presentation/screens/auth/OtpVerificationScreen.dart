import 'dart:async';
import 'dart:ui';
import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/constants/strings.dart';
import 'package:fluent/cubit/auth/resend_otp/resend_otp_cubit.dart';
import 'package:fluent/cubit/auth/resend_otp/resend_otp_state.dart';
import 'package:fluent/cubit/auth/verify_otp/verify_otp_cubit.dart';
import 'package:fluent/cubit/auth/verify_otp/verify_otp_state.dart';
import 'package:fluent/presentation/screens/placementTestDialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String type; // ✅ إضافة type parameter

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.type, // ✅ إضافة type parameter
  });

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

  // ✅ Countdown Timer
  int _remainingSeconds = 60;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
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

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
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

  // ✅ جلب OTP كامل
  String _getFullOtp() {
    return _controllers.map((c) => c.text).join();
  }

  // ✅ مسح كل الخانات
  void _clearOtpFields() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
  }

  // ✅ جلب أول خطأ من الباك اند
  String? _getError(Object state, String field) {
    if (state is VerifyOtpFailure && state.errors != null) {
      final fieldErrors = state.errors![field];
      if (fieldErrors != null) {
        if (fieldErrors is List && fieldErrors.isNotEmpty) {
          return fieldErrors.first.toString();
        }
        if (fieldErrors is String && fieldErrors.isNotEmpty) {
          return fieldErrors;
        }
      }
    }
    return null;
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
            child: MultiBlocListener(
              listeners: [
                // ✅ Listener للـ VerifyOtpCubit
                BlocListener<VerifyOtpCubit, VerifyOtpState>(
                  listener: (context, state) {
                    if (state is VerifyOtpSuccess) {
                      // ✅ نجاح التحقق
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

                      // ✅ التوجيه بناءً على الـ type
                      if (widget.type == OtpType.register) {
                        // ✅ NEW USER = دائماً يروح لـ Student Home
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          studentHomeRoute,
                          (route) => false,
                        );
                        Future.delayed(Duration(milliseconds: 500), () {
                          showDialog(
                            context: context,
                            builder: (_) => PlacementTestDialog(),
                          );
                        });
                      } else if (widget.type == OtpType.forgotPassword) {
                        // ✅ Forgot Password = يروح لـ SetNewPasswordScreen
                        Navigator.pushReplacementNamed(
                          context,
                          setNewPasswordRoute,
                          arguments: widget.email,
                        );
                      }
                    } else if (state is VerifyOtpFailure) {
                      // ✅ فشل التحقق - عرض رسالة + مسح الخانات
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.error),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                      _clearOtpFields();
                    }
                  },
                ),
                // ✅ Listener للـ ResendOtpCubit
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
                      _startCountdown(); // إعادة تشغيل الـ countdown
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
              child: BlocBuilder<VerifyOtpCubit, VerifyOtpState>(
                builder: (context, verifyState) {
                  final isVerifying = verifyState is VerifyOtpLoading;
                  final otpError = _getError(verifyState, 'otp');

                  return BlocBuilder<ResendOtpCubit, ResendOtpState>(
                    builder: (context, resendState) {
                      final isResending = resendState is ResendOtpLoading;

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Column(
                          children: [
                            SizedBox(height: 20.h),
                            _buildTopBar(),
                            SizedBox(height: 30.h),
                            _buildLogoAndTitle(),
                            SizedBox(height: 20.h),
                            // ✅ عرض الإيميل
                            _buildEmailDisplay(),
                            SizedBox(height: 20.h),
                            _glassOtpForm(
                              isVerifying: isVerifying,
                              isResending: isResending,
                              otpError: otpError,
                            ),
                            SizedBox(height: 40.h),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ عرض الإيميل المرسل إليه OTP
  Widget _buildEmailDisplay() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.email_outlined, color: AppColors.yellow, size: 20.sp),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              widget.email,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
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

  Widget _glassOtpForm({
    required bool isVerifying,
    required bool isResending,
    String? otpError,
  }) {
    final bool hasError = otpError != null && otpError.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(35.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(35.r),
            color: Colors.white.withOpacity(.12),
            border: Border.all(
              color: hasError
                  ? Colors.redAccent.withOpacity(0.5)
                  : Colors.white.withOpacity(.25),
            ),
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
                    (index) => _buildSingleOtpField(index, hasError: hasError),
                  ),
                ),
                // ✅ عرض الخطأ تحت الخانات
                if (hasError)
                  Padding(
                    padding: EdgeInsets.only(top: 16.h, left: 8.w, right: 8.w),
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        otpError!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.redAccent,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: 35.h),
                _buildConfirmButton(isVerifying: isVerifying),
                SizedBox(height: 24.h),
                GestureDetector(
                  onTap: _canResend && !isResending
                      ? () {
                          // ✅ استخدام widget.type بدلاً من OtpType.register
                          context.read<ResendOtpCubit>().resendOtp(
                            email: widget.email,
                            type: widget.type,
                          );
                        }
                      : null,
                  child: Text(
                    "Resend Code?",
                    style: GoogleFonts.poppins(
                      color: _canResend
                          ? AppColors.yellow
                          : Colors.white.withOpacity(0.4),
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                // ✅ Countdown timer
                Text(
                  _canResend
                      ? "You can resend now"
                      : "Resend in 0:${_remainingSeconds.toString().padLeft(2, '0')}",
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

  Widget _buildSingleOtpField(int index, {bool hasError = false}) {
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
                  border: hasError
                      ? Border.all(color: Colors.redAccent, width: 2)
                      : null,
                  boxShadow: hasFocus
                      ? [
                          BoxShadow(
                            color: hasError
                                ? Colors.redAccent.withOpacity(0.6)
                                : AppColors.sky.withOpacity(0.6),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: hasError
                                ? Colors.redAccent.withOpacity(0.3)
                                : AppColors.sky.withOpacity(0.3),
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
                        color: hasError
                            ? Colors.redAccent.withOpacity(0.7)
                            : AppColors.sky.withOpacity(0.45),
                        width: 1.8,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      borderSide: BorderSide(
                        color: hasError ? Colors.redAccent : AppColors.sky,
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

  Widget _buildConfirmButton({required bool isVerifying}) {
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
            onTap: isVerifying
                ? null
                : () {
                    String otpCode = _getFullOtp();
                    if (otpCode.length == 6) {
                      // ✅ استخدام widget.type بدلاً من OtpType.register
                      context.read<VerifyOtpCubit>().verifyOtp(
                        email: widget.email,
                        otp: otpCode,
                        type: widget.type,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Please enter the complete 6-digit code',
                          ),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      );
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
                child: isVerifying
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
