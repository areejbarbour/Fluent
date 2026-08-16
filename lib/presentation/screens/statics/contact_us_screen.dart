import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/cubit/contact_us/contact_us_cubit.dart';
import 'package:fluent/cubit/contact_us/contact_us_state.dart';
import 'package:fluent/presentation/widgets/app_backdrop.dart';
import 'package:fluent/presentation/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<ContactUsCubit>().sendMessage(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    // AppBackdrop has NO child param — it is a background layer only.
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Stack(
        children: [
          const AppBackdrop(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Contact Us',
                        style: GoogleFonts.poppins(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: BlocConsumer<ContactUsCubit, ContactUsState>(
                    listener: (context, state) {
                      if (state is ContactUsSuccess) {
                        showAppSnackBar(
                          context,
                          state.message,
                          type: AppSnackType.success,
                        );
                        _controller.clear();
                        context.read<ContactUsCubit>().reset();
                      } else if (state is ContactUsFailure) {
                        showAppSnackBar(
                          context,
                          state.message,
                          type: AppSnackType.error,
                        );
                      }
                    },
                    builder: (context, state) {
                      final loading = state is ContactUsLoading;
                      return SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Send us a message and we will get back to you.',
                                style: GoogleFonts.poppins(
                                  fontSize: 14.sp,
                                  color: Colors.white70,
                                ),
                              ),
                              SizedBox(height: 20.h),
                              TextFormField(
                                controller: _controller,
                                enabled: !loading,
                                maxLines: 8,
                                maxLength: 2000,
                                style: GoogleFonts.poppins(
                                  color: AppColors.dark,
                                ),
                                decoration: InputDecoration(
                                  hintText:
                                      'Write your message (min 10 characters)...',
                                  hintStyle: GoogleFonts.poppins(
                                    color: AppColors.dark.withOpacity(0.45),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.95),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14.r),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14.r),
                                    borderSide: BorderSide(
                                      color: AppColors.primary,
                                      width: 1.5,
                                    ),
                                  ),
                                  counterStyle: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                ),
                                validator: (v) {
                                  final t = (v ?? '').trim();
                                  if (t.length < 10) {
                                    return 'Message must be at least 10 characters.';
                                  }
                                  if (t.length > 2000) {
                                    return 'Message must be at most 2000 characters.';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 20.h),
                              SizedBox(
                                height: 48.h,
                                child: ElevatedButton(
                                  onPressed: loading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                  ),
                                  child: loading
                                      ? SizedBox(
                                          width: 22.w,
                                          height: 22.w,
                                          child:
                                              const CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                        )
                                      : Text(
                                          'Send Message',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15.sp,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
