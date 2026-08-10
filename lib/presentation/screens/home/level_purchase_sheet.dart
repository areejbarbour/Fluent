import 'dart:ui';

import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/cubit/student/payment/payment_cubit.dart';
import 'package:fluent/cubit/student/payment/payment_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_fonts/google_fonts.dart';

class LevelPurchaseSheet extends StatefulWidget {
  final int levelId;
  final String levelTitle;
  final String levelSubtitle;
  final double? price;
  final List<Color>? colors;
  final VoidCallback? onSuccess;

  const LevelPurchaseSheet({
    super.key,
    required this.levelId,
    required this.levelTitle,
    this.levelSubtitle = '',
    this.price,
    this.colors,
    this.onSuccess,
  });

  @override
  State<LevelPurchaseSheet> createState() => _LevelPurchaseSheetState();
}

class _LevelPurchaseSheetState extends State<LevelPurchaseSheet> {
  String? _formError;

  List<Color> get _colors =>
      widget.colors ?? [AppColors.orange, AppColors.yellow];

  Future<void> _pay() async {
    setState(() => _formError = null);
    HapticFeedback.mediumImpact();
    context.read<PaymentCubit>().createIntent(widget.levelId);
  }

  Future<void> _presentStripe(String clientSecret, String paymentIntentId) async {
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Fluent',
          style: ThemeMode.dark,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      if (!mounted) return;
      context.read<PaymentCubit>().checkStatus(paymentIntentId);
    } on StripeException catch (e) {
      if (!mounted) return;
      setState(() {
        _formError = e.error.localizedMessage ?? 'Payment cancelled';
      });
      context.read<PaymentCubit>().reset();
    } catch (_) {
      if (!mounted) return;
      setState(() => _formError = 'Something went wrong. Please try again.');
      context.read<PaymentCubit>().reset();
    }
  }

  void _showSuccessSnack(String message) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(.15),
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: const Color(0xFF4ADE80),
                size: 18.sp,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5.sp,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _inlineErrorBanner(String message) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.14),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.redAccent.withOpacity(0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 18.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                color: Colors.red.shade200,
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _formError = null),
            child: Icon(
              Icons.close_rounded,
              color: Colors.white38,
              size: 16.sp,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaymentCubit, PaymentState>(
      listener: (context, state) async {
        if (state is PaymentIntentSuccess) {
          await _presentStripe(
            state.intent.clientSecret,
            state.intent.paymentIntentId,
          );
        } else if (state is PaymentStatusSuccess) {
          if (state.status.isSucceeded) {
            Navigator.pop(context);
            _showSuccessSnack('Level unlocked successfully!');
            widget.onSuccess?.call();
          } else if (state.status.isPending) {
            setState(() {
              _formError =
                  'Payment is still pending. Please wait a moment and try again.';
            });
          } else if (state.status.isFailed) {
            setState(() => _formError = 'Payment failed. Please try again.');
          }
          context.read<PaymentCubit>().reset();
        } else if (state is PaymentFailure) {
          setState(() => _formError = state.message);
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 28.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.dark.withOpacity(.95),
                    AppColors.primary.withOpacity(.55),
                    AppColors.dark.withOpacity(.92),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(28.r)),
                border: Border(
                  top: BorderSide(color: Colors.white.withOpacity(.14)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.sky.withOpacity(.12),
                    blurRadius: 30,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _colors.first.withOpacity(.5),
                              _colors.last.withOpacity(.5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 18.h),

                    // Header
                    Row(
                      children: [
                        Container(
                          width: 50.w,
                          height: 50.w,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15.r),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                _colors.first.withOpacity(.30),
                                _colors.last.withOpacity(.20),
                              ],
                            ),
                            border: Border.all(
                              color: _colors.first.withOpacity(.45),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _colors.first.withOpacity(.30),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.credit_card_rounded,
                            color: _colors.first,
                            size: 23.sp,
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Unlock Level',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16.sp,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              SizedBox(height: 3.h),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 3.h,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      _colors.first.withOpacity(.25),
                                      _colors.last.withOpacity(.15),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: _colors.first.withOpacity(.35),
                                  ),
                                ),
                                child: Text(
                                  widget.levelTitle,
                                  style: GoogleFonts.poppins(
                                    color: _colors.first,
                                    fontSize: 11.5.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.price != null) ...[
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: _colors),
                              borderRadius: BorderRadius.circular(12.r),
                              boxShadow: [
                                BoxShadow(
                                  color: _colors.first.withOpacity(.35),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Text(
                              '\$${widget.price!.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        ],
                      ],
                    )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .moveY(begin: 8, end: 0),

                    SizedBox(height: 12.h),

                    Text(
                      widget.levelSubtitle.isNotEmpty
                          ? widget.levelSubtitle
                          : 'Complete a secure payment to unlock this level and start learning.',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(.55),
                        fontSize: 11.5.sp,
                        height: 1.45,
                      ),
                    ).animate().fadeIn(delay: 60.ms, duration: 400.ms),

                    SizedBox(height: 20.h),

                    if (_formError != null) _inlineErrorBanner(_formError!),

                    // Info card
                    Container(
                      padding: EdgeInsets.all(14.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14.r),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(.08),
                            Colors.white.withOpacity(.03),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(.12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: _colors.first.withOpacity(.15),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Icon(
                              Icons.shield_rounded,
                              color: _colors.first,
                              size: 18.sp,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              'Secure card payment via Stripe. You can use a test card in sandbox mode.',
                              style: GoogleFonts.poppins(
                                color: Colors.white.withOpacity(.70),
                                fontSize: 11.5.sp,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                    SizedBox(height: 24.h),

                    // Pay button
                    BlocBuilder<PaymentCubit, PaymentState>(
                      builder: (context, state) {
                        final isLoading = state is PaymentLoading;

                        return GestureDetector(
                          onTap: isLoading ? null : _pay,
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isLoading
                                    ? [
                                        AppColors.orange.withOpacity(.45),
                                        AppColors.yellow.withOpacity(.45),
                                      ]
                                    : [AppColors.orange, AppColors.yellow],
                              ),
                              borderRadius: BorderRadius.circular(16.r),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.yellow.withOpacity(
                                    isLoading ? .15 : .40,
                                  ),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: isLoading
                                  ? SizedBox(
                                      width: 22.sp,
                                      height: 22.sp,
                                      child: const CircularProgressIndicator(
                                        color: Colors.black,
                                        strokeWidth: 2.4,
                                      ),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.lock_open_rounded,
                                          color: Colors.black,
                                          size: 17.sp,
                                        ),
                                        SizedBox(width: 8.w),
                                        Text(
                                          widget.price != null
                                              ? 'Pay \$${widget.price!.toStringAsFixed(0)} & Unlock'
                                              : 'Pay & Unlock',
                                          style: GoogleFonts.poppins(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14.sp,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        );
                      },
                    ).animate().fadeIn(delay: 160.ms, duration: 400.ms),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}