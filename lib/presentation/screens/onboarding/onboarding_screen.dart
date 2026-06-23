import 'dart:ui';
import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/constants/strings.dart'; // تم إضافة هذا الاستيراد
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../helper/onboarding_model.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<OnboardingModel> _pages = [
    OnboardingModel(
      image: "assets/images/onboarding/onboarding1.png",
      title: "LEARN ENGAGINGLY\nInteractive Lessons",
      subtitle:
          "Master vocabulary and grammar through games, stories, and engaging challenges. Get started on a playful path to fluency!",
      buttonText: "START YOUR JOURNEY",
      isFilledButton: true,
    ),
    OnboardingModel(
      image: "assets/images/onboarding/onboarding2.png",
      title: "AI CONVERSATION PARTNER",
      subtitle:
          "Practice speaking anytime with our advanced AI. Get instant feedback on your pronunciation and dialogue.",
      buttonText: "CHAT & PROGRESS",
      isFilledButton: false,
    ),
    OnboardingModel(
      image: "assets/images/onboarding/onboarding3.png",
      title: "UNLIMITED GROWTH",
      subtitle:
          "Move up levels, unlock new courses, and track your progress to earn a valuable university-partnered certificate!",
      buttonText: "BEGIN YOUR COURSE",
      isFilledButton: true,
    ),
  ];

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
            top: -120,
            left: -80,
            child: Container(
              width: 280.w,
              height: 280.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.yellow.withOpacity(.12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.yellow.withOpacity(.5),
                    blurRadius: 150,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 320.w,
              height: 320.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.sky.withOpacity(.10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.sky.withOpacity(.4),
                    blurRadius: 180,
                    spreadRadius: 60,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return _buildPageContent(_pages[index]);
                    },
                  ),
                ),
                _buildBottomControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(
            radius: 20.r,
            backgroundColor: Colors.black.withOpacity(0.15),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 16.sp,
              ),
              onPressed: null,
            ),
          ),
          TextButton(
            onPressed: () {
              // الانتقال إلى شاشة تسجيل الدخول عند الضغط على Skip
              Navigator.pushReplacementNamed(context, loginRoute);
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
                side: BorderSide(color: Colors.white.withOpacity(0.3)),
              ),
            ),
            child: Text(
              "Skip",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(OnboardingModel page) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          SizedBox(height: 10.h),
          Expanded(
            flex: 5,
            child: Center(
              child: Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.08),
                  borderRadius: BorderRadius.circular(35.r),
                  border: Border.all(color: Colors.white.withOpacity(.15)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.15),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25.r),
                  child: Image.asset(page.image, fit: BoxFit.contain)
                      .animate()
                      .fadeIn(duration: 700.ms)
                      .scale(begin: const Offset(.85, .85))
                      .moveY(begin: 40),
                ),
              ),
            ),
          ),
          SizedBox(height: 25.h),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 30.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ).animate().fadeIn(delay: 250.ms).moveY(begin: 20),
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.h),
            child: Text(
              page.subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(.85),
                fontSize: 15.sp,
                height: 1.7,
              ),
            ).animate().fadeIn(delay: 450.ms),
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    final currentPageData = _pages[_currentIndex];

    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 30.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SmoothPageIndicator(
            controller: _pageController,
            count: _pages.length,
            effect: ExpandingDotsEffect(
              activeDotColor: AppColors.yellow,
              dotColor: Colors.white24,
              dotHeight: 8.h,
              dotWidth: 8.w,
              expansionFactor: 4,
            ),
          ),
          SizedBox(height: 25.h),
          // تم تغليف الزر بـ GestureDetector لتفعيل التنقل
          GestureDetector(
            onTap: () {
              if (_currentIndex < _pages.length - 1) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              } else {
                // في الصفحة الأخيرة ينتقل إلى شاشة تسجيل الدخول
                Navigator.pushReplacementNamed(context, loginRoute);
              }
            },
            child: Container(
              width: double.infinity,
              height: 60.h,
              decoration: BoxDecoration(
                gradient: currentPageData.isFilledButton
                    ? const LinearGradient(
                        colors: [AppColors.orange, AppColors.yellow],
                      )
                    : null,
                color: currentPageData.isFilledButton
                    ? null
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(18.r),
                border: currentPageData.isFilledButton
                    ? null
                    : Border.all(color: AppColors.yellow, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.orange.withOpacity(.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  currentPageData.buttonText,
                  style: GoogleFonts.poppins(
                    color: currentPageData.isFilledButton
                        ? AppColors.dark
                        : AppColors.yellow,
                    fontWeight: FontWeight.w700,
                    fontSize: 16.sp,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 700.ms).scale(),
          ),
        ],
      ),
    );
  }
}
