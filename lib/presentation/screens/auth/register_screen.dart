import 'dart:ui';
import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/constants/strings.dart';
import 'package:fluent/cubit/auth/google_sign_in/google_sign_in_cubit.dart';
import 'package:fluent/cubit/auth/google_sign_in/google_sign_in_state.dart';
import 'package:fluent/cubit/auth/sign_up/sign_up_cubit.dart';
import 'package:fluent/cubit/auth/sign_up/sign_up_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final _formKey = GlobalKey<FormState>();

  // ✅ Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ✅ Helper: جلب أول خطأ من الباك اند لـ field معين
  String? _getError(SignUpState state, String field) {
    if (state is SignUpFailure && state.errors != null) {
      print("🔍 [_getError] Checking errors for field: $field");
      print("🔍 [_getError] State errors: ${state.errors}");

      final fieldErrors = state.errors![field];
      print(" [_getError] Field errors for '$field': $fieldErrors");

      if (fieldErrors != null) {
        if (fieldErrors is List && fieldErrors.isNotEmpty) {
          final errorMsg = fieldErrors.first.toString();
          print("🔍 [_getError] Returning: $errorMsg");
          return errorMsg;
        }
        if (fieldErrors is String && fieldErrors.isNotEmpty) {
          print("🔍 [_getError] Returning string: $fieldErrors");
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
            child: BlocConsumer<SignUpCubit, SignUpState>(
              listener: (context, state) {
                if (state is SignUpSuccess) {
                  // ✅ نجاح التسجيل - الانتقال إلى OTP
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
                  Navigator.pushReplacementNamed(
                    context,
                    otpRoute,
                    arguments: _emailController.text.trim(),
                  );
                } else if (state is SignUpFailure) {
                  // ✅ التحقق إذا كان الخطأ بسبب وجود الإيميل مسبقاً
                  final emailError = state.errors?['email'];
                  final isEmailTaken =
                      emailError != null &&
                      emailError.any((error) {
                        final errorMsg = error.toString().toLowerCase();
                        return errorMsg.contains('already been taken') ||
                            errorMsg.contains('already exists') ||
                            errorMsg.contains('taken');
                      });

                  if (isEmailTaken) {
                    // ✅ توجيه إلى Login مع تمرير الإيميل
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'This email is already registered. Please login instead.',
                        ),
                        backgroundColor: AppColors.yellow,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        duration: const Duration(seconds: 3),
                        action: SnackBarAction(
                          label: 'Login',
                          textColor: Colors.black,
                          //  fontWeight: FontWeight.w700,
                          onPressed: () {
                            Navigator.pushReplacementNamed(
                              context,
                              loginRoute,
                              arguments: _emailController.text.trim(),
                            );
                          },
                        ),
                      ),
                    );

                    // ✅ الانتقال التلقائي بعد 1.5 ثانية
                    Future.delayed(const Duration(milliseconds: 1500), () {
                      Navigator.pushReplacementNamed(
                        context,
                        loginRoute,
                        arguments: _emailController.text.trim(),
                      );
                    });
                  }
                  // ✅ الأخطاء الأخرى ستظهر تحت الحقول تلقائياً عبر _getError
                }
              },
              builder: (context, state) {
                final isLoading = state is SignUpLoading;

                // ✅ جلب الأخطاء من الباك اند لكل field
                final firstNameError = _getError(state, 'first_name');
                final lastNameError = _getError(state, 'last_name');
                final emailError = _getError(state, 'email');
                final passwordError = _getError(state, 'password');

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    children: [
                      SizedBox(height: 20.h),
                      _buildTopBar(),
                      SizedBox(height: 30.h),
                      _buildLogoAndTitle(),
                      SizedBox(height: 40.h),
                      _glassForm(
                        isLoading: isLoading,
                        firstNameError: firstNameError,
                        lastNameError: lastNameError,
                        emailError: emailError,
                        passwordError: passwordError,
                      ),
                      SizedBox(height: 24.h),
                      _googleButton(),
                      SizedBox(height: 28.h),
                      _loginLink(),
                      SizedBox(height: 40.h),
                    ],
                  ),
                );
              },
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
              "CREATE YOUR ACCOUNT",
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
              "Get started and begin your English learning journey",
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

  Widget _glassForm({
    required bool isLoading,
    String? firstNameError,
    String? lastNameError,
    String? emailError,
    String? passwordError,
  }) {
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
                _buildInputField(
                  "First Name",
                  Icons.person,
                  controller: _firstNameController,
                  errorText: firstNameError,
                ),
                SizedBox(height: 15.h),
                _buildInputField(
                  "Last Name",
                  Icons.people,
                  controller: _lastNameController,
                  errorText: lastNameError,
                ),
                SizedBox(height: 15.h),
                _buildInputField(
                  "Email Address",
                  Icons.email_outlined,
                  controller: _emailController,
                  errorText: emailError,
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 15.h),
                _buildInputField(
                  "Password",
                  Icons.lock_outline,
                  controller: _passwordController,
                  isPassword: true,
                  errorText: passwordError,
                ),
                SizedBox(height: 15.h),
                _buildInputField(
                  "Confirm Password",
                  Icons.lock_outline,
                  controller: _confirmPasswordController,
                  isPassword: true,
                  isConfirm: true,
                ),
                SizedBox(height: 25.h),
                _buildSignUpButton(isLoading),
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
    required TextEditingController controller,
    String? errorText,
    bool isPassword = false,
    bool isConfirm = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    bool obscure = isConfirm ? _obscureConfirmPassword : _obscurePassword;
    final bool hasError = errorText != null && errorText.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Focus(
          key: ValueKey(hint),
          child: Builder(
            builder: (context) {
              final bool hasFocus = Focus.of(context).hasFocus;
              return TextFormField(
                controller: controller,
                obscureText: isPassword ? obscure : false,
                keyboardType: keyboardType,
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
                            obscure ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white.withOpacity(0.85),
                          ),
                          onPressed: () {
                            setState(() {
                              if (isConfirm) {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              } else {
                                _obscurePassword = !_obscurePassword;
                              }
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
                    borderSide: BorderSide(
                      color: hasError ? Colors.redAccent : AppColors.sky,
                      width: 1.8,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.r),
                    borderSide: BorderSide(
                      color: hasError ? Colors.redAccent : AppColors.sky,
                      width: 2.2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.r),
                    borderSide: const BorderSide(
                      color: Colors.redAccent,
                      width: 1.8,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.r),
                    borderSide: const BorderSide(
                      color: Colors.redAccent,
                      width: 2.2,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // ✅ عرض الخطأ تحت الحقل - يتكيف مع عرض الشاشة
        if (hasError)
          Padding(
            padding: EdgeInsets.only(top: 8.h, left: 8.w, right: 8.w),
            child: SizedBox(
              width: double.infinity,
              child: Text(
                errorText!,
                style: GoogleFonts.poppins(
                  color: Colors.redAccent,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSignUpButton(bool isLoading) {
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
                    _performSignUp();
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
                        "SIGN UP",
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontSize: 25.sp,
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
    return BlocConsumer<GoogleLoginCubit, GoogleLoginState>(
      listener: (context, state) {
        if (state is GoogleLoginSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Google login successful!'),
              backgroundColor: AppColors.sky,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          );

          // ✅ استخراج roles من state
          final roles = state.roles;
          String targetRoute = homeRoute;

          if (roles.isNotEmpty) {
            final role = roles.first;
            String roleName = '';

            if (role is Map) {
              roleName = role['name'] ?? role['title'] ?? '';
            } else {
              roleName = role.toString();
            }

            if (roleName == 'teacher') {
              targetRoute = questionsListRoute;
            } else {
              targetRoute = placementTestDialogRoute;
            }
          }

          Navigator.pushNamedAndRemoveUntil(
            context,

            placementTestDialogRoute, // ← الـ route الجديد

            (route) => false,
          );
        } else if (state is GoogleLoginFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message), // ✅ message وليس error
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is GoogleLoginLoading;

        return InkWell(
          onTap: isLoading
              ? null
              : () {
                  context.read<GoogleLoginCubit>().loginWithGoogle();
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
                if (isLoading)
                  SizedBox(
                    width: 24.w,
                    height: 24.w,
                    child: CircularProgressIndicator(
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.black,
                      ),
                      strokeWidth: 2.5,
                    ),
                  )
                else ...[
                  Image.asset(
                    "assets/images/onboarding/google.png",
                    width: 24.w,
                  ),
                  SizedBox(width: 12.w),
                  Flexible(
                    child: Text(
                      "CONTINUE WITH GOOGLE",
                      style: GoogleFonts.poppins(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.sp,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _loginLink() {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacementNamed(context, loginRoute);
      },
      child: Text.rich(
        TextSpan(
          text: "Already have an account? ",
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13.sp),
          children: [
            TextSpan(
              text: "Log In",
              style: GoogleFonts.poppins(
                color: AppColors.yellow,
                fontWeight: FontWeight.w700,
                fontSize: 15.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Perform Sign Up - بدون validation محلي
  void _performSignUp() {
    context.read<SignUpCubit>().signUp(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      passwordConfirmation: _confirmPasswordController.text,
    );
  }
}
