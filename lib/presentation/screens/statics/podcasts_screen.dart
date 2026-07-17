// // 📁 lib/presentation/screens/podcasts/podcasts_screen.dart

// import 'package:fluent/constants/app_colors.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:google_fonts/google_fonts.dart';

// class PodcastsScreen extends StatelessWidget {
//   const PodcastsScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.dark,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         title: Text(
//           "Podcasts",
//           style: GoogleFonts.poppins(
//             color: Colors.white,
//             fontWeight: FontWeight.w800,
//           ),
//         ),
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.mic_rounded, size: 80.sp, color: AppColors.sky),
//             SizedBox(height: 20.h),
//             Text(
//               "Podcasts Coming Soon 🎙️",
//               style: GoogleFonts.poppins(
//                 color: Colors.white,
//                 fontSize: 18.sp,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:math' as math;
import 'dart:ui';

import 'package:fluent/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// ============================================================
/// MODELS
/// ============================================================

enum PodcastLevel { beginner, intermediate, advanced }

class PodcastItem {
  final String title;
  final String host;
  final int durationMinutes;
  final int points;
  final PodcastLevel level;
  bool isOwned;

  PodcastItem({
    required this.title,
    required this.host,
    required this.durationMinutes,
    required this.points,
    required this.level,
    this.isOwned = false,
  });
}

class PodcastCategory {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<PodcastItem> podcasts;

  const PodcastCategory({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.podcasts,
  });

  int get ownedCount => podcasts.where((p) => p.isOwned).length;
}

/// ============================================================
/// MOCK DATA
/// ============================================================
// ✅ TODO: هاي بيانات وهمية للعرض — اربطيها مع الـ API / Cubit الحقيقي
// عندك (PodcastsCubit مثلاً) بدل القائمة الثابتة.
final List<PodcastCategory> _mockCategories = [
  PodcastCategory(
    title: "Business English",
    subtitle: "Professional & workplace talk",
    icon: Icons.business_center_rounded,
    color: AppColors.sky,
    podcasts: [
      PodcastItem(title: "Negotiation Basics", host: "Sarah K.", durationMinutes: 12, points: 0, level: PodcastLevel.intermediate, isOwned: true),
      PodcastItem(title: "Writing Professional Emails", host: "James R.", durationMinutes: 9, points: 40, level: PodcastLevel.beginner),
      PodcastItem(title: "Leading Meetings with Confidence", host: "Sarah K.", durationMinutes: 15, points: 65, level: PodcastLevel.advanced),
      PodcastItem(title: "Job Interview Mastery", host: "Omar T.", durationMinutes: 18, points: 80, level: PodcastLevel.intermediate),
    ],
  ),
  PodcastCategory(
    title: "Travel & Culture",
    subtitle: "Explore the world in English",
    icon: Icons.flight_takeoff_rounded,
    color: AppColors.orange,
    podcasts: [
      PodcastItem(title: "At the Airport", host: "Lina M.", durationMinutes: 8, points: 0, level: PodcastLevel.beginner, isOwned: true),
      PodcastItem(title: "Ordering Food Abroad", host: "Lina M.", durationMinutes: 10, points: 30, level: PodcastLevel.beginner),
      PodcastItem(title: "Cultural Etiquette Tips", host: "David P.", durationMinutes: 14, points: 55, level: PodcastLevel.intermediate),
      PodcastItem(title: "Backpacking Stories", host: "Ziad H.", durationMinutes: 20, points: 90, level: PodcastLevel.advanced),
    ],
  ),
  PodcastCategory(
    title: "Daily Conversations",
    subtitle: "Everyday real-life talk",
    icon: Icons.chat_bubble_rounded,
    color: AppColors.yellow,
    podcasts: [
      PodcastItem(title: "Small Talk 101", host: "Emma W.", durationMinutes: 7, points: 0, level: PodcastLevel.beginner, isOwned: true),
      PodcastItem(title: "At the Coffee Shop", host: "Emma W.", durationMinutes: 6, points: 20, level: PodcastLevel.beginner),
      PodcastItem(title: "Making Plans with Friends", host: "Karim S.", durationMinutes: 9, points: 35, level: PodcastLevel.intermediate),
      PodcastItem(title: "Handling Awkward Moments", host: "Emma W.", durationMinutes: 11, points: 45, level: PodcastLevel.intermediate),
    ],
  ),
  PodcastCategory(
    title: "Grammar Tips",
    subtitle: "Bite-sized grammar lessons",
    icon: Icons.menu_book_rounded,
    color: Color(0xffB388FF),
    podcasts: [
      PodcastItem(title: "Present Perfect Simplified", host: "Dr. Noor", durationMinutes: 10, points: 25, level: PodcastLevel.beginner),
      PodcastItem(title: "Conditionals Made Easy", host: "Dr. Noor", durationMinutes: 13, points: 40, level: PodcastLevel.intermediate),
      PodcastItem(title: "Common Mistakes to Avoid", host: "Dr. Noor", durationMinutes: 9, points: 30, level: PodcastLevel.beginner),
    ],
  ),
  PodcastCategory(
    title: "Storytelling",
    subtitle: "Short stories to boost listening",
    icon: Icons.auto_stories_rounded,
    color: Color(0xffFF6FB5),
    podcasts: [
      PodcastItem(title: "The Lighthouse Keeper", host: "Narrated by Alex", durationMinutes: 16, points: 50, level: PodcastLevel.intermediate),
      PodcastItem(title: "A Day in Tokyo", host: "Narrated by Mia", durationMinutes: 14, points: 45, level: PodcastLevel.beginner),
      PodcastItem(title: "The Last Train Home", host: "Narrated by Alex", durationMinutes: 22, points: 95, level: PodcastLevel.advanced),
    ],
  ),
  PodcastCategory(
    title: "News & Media",
    subtitle: "Current events, clearly explained",
    icon: Icons.newspaper_rounded,
    color: Color(0xFF4ADE80),
    podcasts: [
      PodcastItem(title: "Tech Trends This Week", host: "Ryan B.", durationMinutes: 11, points: 35, level: PodcastLevel.intermediate),
      PodcastItem(title: "Understanding Headlines", host: "Ryan B.", durationMinutes: 9, points: 30, level: PodcastLevel.beginner),
      PodcastItem(title: "Global Economy Explained", host: "Dr. Noor", durationMinutes: 17, points: 70, level: PodcastLevel.advanced),
    ],
  ),
];

/// ============================================================
/// SHARED BACKGROUND (نفس هوية باقي الشاشات)
/// ============================================================
Widget podcastsBackground() {
  return Stack(
    children: [
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xff011826),
              AppColors.dark,
              AppColors.primary,
              Color(0xff01466A),
              AppColors.dark,
            ],
            stops: [0.0, 0.2, 0.55, 0.8, 1.0],
          ),
        ),
      ),
      Positioned(
        top: -120.h,
        right: -80.w,
        child: _glowCircle(AppColors.yellow, 300.w, 160, 40)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .move(begin: Offset.zero, end: const Offset(-15, 10), duration: 5500.ms, curve: Curves.easeInOut),
      ),
      Positioned(
        top: 420.h,
        left: -100.w,
        child: _glowCircle(AppColors.sky, 260.w, 150, 30)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .move(begin: Offset.zero, end: const Offset(20, 15), duration: 6500.ms, curve: Curves.easeInOut),
      ),
      Positioned(
        top: 850.h,
        right: -60.w,
        child: _glowCircle(const Color(0xffB861F5), 220.w, 140, 25)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .move(begin: Offset.zero, end: const Offset(-10, -8), duration: 7000.ms, curve: Curves.easeInOut),
      ),
    ],
  );
}

Widget _glowCircle(Color color, double size, double blur, double spread) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color.withOpacity(0.10),
      boxShadow: [BoxShadow(color: color.withOpacity(0.30), blurRadius: blur, spreadRadius: spread)],
    ),
  );
}

class TwinklingStars extends StatelessWidget {
  final int count;
  const TwinklingStars({super.key, this.count = 32});

  @override
  Widget build(BuildContext context) {
    final rng = math.Random(17);
    return IgnorePointer(
      child: Stack(
        children: List.generate(count, (i) {
          final left = rng.nextDouble();
          final top = rng.nextDouble();
          final size = rng.nextDouble() * 2 + 1;
          final delay = rng.nextInt(3000);
          final duration = 1500 + rng.nextInt(2500);
          final maxOpacity = rng.nextDouble() * 0.6 + 0.3;
          final hasGlow = rng.nextBool();

          return Positioned(
            left: left * 1.sw,
            top: top * 1.sh,
            child: Container(
              width: size.w,
              height: size.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: hasGlow
                    ? [BoxShadow(color: Colors.white.withOpacity(0.7), blurRadius: 4, spreadRadius: 0.5)]
                    : null,
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .fade(begin: 0, end: maxOpacity, duration: duration.ms, delay: delay.ms)
                .then()
                .fade(begin: maxOpacity, end: 0, duration: duration.ms),
          );
        }),
      ),
    );
  }
}

Widget glassBox({
  required Widget child,
  EdgeInsetsGeometry? padding,
  double radius = 20,
  List<Color>? gradientColors,
  Color? borderColor,
}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors ?? [Colors.white.withOpacity(.10), Colors.white.withOpacity(.04)],
          ),
          border: Border.all(color: borderColor ?? Colors.white.withOpacity(.15)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.15), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: child,
      ),
    ),
  );
}

String levelLabel(PodcastLevel l) {
  switch (l) {
    case PodcastLevel.beginner:
      return "Beginner";
    case PodcastLevel.intermediate:
      return "Intermediate";
    case PodcastLevel.advanced:
      return "Advanced";
  }
}

Color levelColor(PodcastLevel l) {
  switch (l) {
    case PodcastLevel.beginner:
      return const Color(0xFF4ADE80);
    case PodcastLevel.intermediate:
      return AppColors.yellow;
    case PodcastLevel.advanced:
      return Colors.redAccent;
  }
}

/// ============================================================
/// PODCASTS SCREEN (Categories)
/// ============================================================
class PodcastsScreen extends StatefulWidget {
  const PodcastsScreen({super.key});

  @override
  State<PodcastsScreen> createState() => _PodcastsScreenState();
}

class _PodcastsScreenState extends State<PodcastsScreen> {
  // ✅ TODO: اربطي رصيد النقاط الحقيقي من الـ backend / Wallet Cubit
  int _userPoints = 450;
  final List<PodcastCategory> _categories = _mockCategories;

  Future<void> _openCategory(PodcastCategory category) async {
    HapticFeedback.selectionClick();
    final updatedPoints = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => PodcastListScreen(
          category: category,
          userPoints: _userPoints,
        ),
      ),
    );
    if (updatedPoints != null && mounted) {
      setState(() => _userPoints = updatedPoints);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      body: Stack(
        children: [
          podcastsBackground(),
          const TwinklingStars(count: 30),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(),
                  SizedBox(height: 18.h),
                  _buildIntroBanner(),
                  SizedBox(height: 20.h),
                  Text(
                    "Browse Topics",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
                  SizedBox(height: 12.h),
                  _buildCategoriesGrid(),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        _circleIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.pop(context),
        ),
        Expanded(
          child: Text(
            "Podcasts",
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(width: 44.w),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _circleIconButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Colors.white.withOpacity(.14), Colors.white.withOpacity(.06)],
          ),
          border: Border.all(color: Colors.white.withOpacity(.25)),
        ),
        child: Icon(icon, color: Colors.white, size: 18.sp),
      ),
    );
  }

  Widget _buildIntroBanner() {
    final totalOwned = _categories.fold<int>(0, (sum, c) => sum + c.ownedCount);
    final totalPodcasts = _categories.fold<int>(0, (sum, c) => sum + c.podcasts.length);

    return glassBox(
      padding: EdgeInsets.all(16.w),
      radius: 24.r,
      gradientColors: [
        AppColors.primary.withOpacity(.6),
        const Color(0xff01466A).withOpacity(.5),
      ],
      borderColor: Colors.white.withOpacity(.18),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [AppColors.yellow, AppColors.orange],
              ),
              boxShadow: [BoxShadow(color: AppColors.yellow.withOpacity(.5), blurRadius: 14)],
            ),
            child: Icon(Icons.headset_rounded, color: Colors.black, size: 22.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Listen & Learn",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  "$totalOwned/$totalPodcasts episodes unlocked",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(.6),
                    fontSize: 10.5.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          // ================= محفظة النقاط =================
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.orange, AppColors.yellow]),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [BoxShadow(color: AppColors.yellow.withOpacity(.5), blurRadius: 10)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.diamond_rounded, color: Colors.black, size: 13.sp),
                SizedBox(width: 4.w),
                Text(
                  "$_userPoints",
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 50.ms, duration: 450.ms).moveY(begin: 10, end: 0);
  }

  Widget _buildCategoriesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _categories.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 0.92,
      ),
      itemBuilder: (context, i) {
        final category = _categories[i];
        return _categoryCard(category, i);
      },
    );
  }

  Widget _categoryCard(PodcastCategory category, int index) {
    return GestureDetector(
      onTap: () => _openCategory(category),
      child: glassBox(
        padding: EdgeInsets.all(14.w),
        radius: 22.r,
        gradientColors: [
          category.color.withOpacity(.20),
          Colors.white.withOpacity(.04),
        ],
        borderColor: category.color.withOpacity(.35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [category.color.withOpacity(.4), category.color.withOpacity(.08)],
                ),
                boxShadow: [BoxShadow(color: category.color.withOpacity(.4), blurRadius: 10)],
              ),
              child: Icon(category.icon, color: category.color, size: 22.sp),
            ),
            SizedBox(height: 12.h),
            Text(
              category.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13.sp,
                height: 1.2,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              category.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(.55),
                fontSize: 9.sp,
                height: 1.3,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Icon(Icons.podcasts_rounded, color: Colors.white38, size: 12.sp),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    "${category.podcasts.length} episodes",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(.5),
                      fontSize: 9.sp,
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: category.color, size: 10.sp),
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (100 + index * 70).ms, duration: 450.ms)
        .scale(begin: const Offset(.9, .9), end: const Offset(1, 1), curve: Curves.easeOutBack);
  }
}

/// ============================================================
/// PODCAST LIST SCREEN (episodes within a category)
/// ============================================================
class PodcastListScreen extends StatefulWidget {
  final PodcastCategory category;
  final int userPoints;

  const PodcastListScreen({
    super.key,
    required this.category,
    required this.userPoints,
  });

  @override
  State<PodcastListScreen> createState() => _PodcastListScreenState();
}

class _PodcastListScreenState extends State<PodcastListScreen> {
  late int _userPoints = widget.userPoints;
  String _filter = "All"; // All / Owned / Locked

  List<PodcastItem> get _filteredPodcasts {
    switch (_filter) {
      case "Owned":
        return widget.category.podcasts.where((p) => p.isOwned).toList();
      case "Locked":
        return widget.category.podcasts.where((p) => !p.isOwned).toList();
      default:
        return widget.category.podcasts;
    }
  }

  void _handlePodcastTap(PodcastItem podcast) {
    if (podcast.isOwned) {
      HapticFeedback.lightImpact();
      // ✅ TODO: افتحي مشغّل البودكاست الفعلي هون
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("▶ Playing \"${podcast.title}\"..."),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
      );
      return;
    }
    _showPurchaseSheet(podcast);
  }

  void _showPurchaseSheet(PodcastItem podcast) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final canAfford = _userPoints >= podcast.points;
            return ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 26.h),
                  decoration: BoxDecoration(
                    color: AppColors.dark.withOpacity(.92),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
                    border: Border(top: BorderSide(color: Colors.white.withOpacity(.12))),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.25),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Container(
                        width: 64.w,
                        height: 64.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [widget.category.color.withOpacity(.4), widget.category.color.withOpacity(.08)],
                          ),
                        ),
                        child: Icon(Icons.podcasts_rounded, color: widget.category.color, size: 30.sp),
                      ),
                      SizedBox(height: 14.h),
                      Text(
                        podcast.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16.sp,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        "${podcast.host} • ${podcast.durationMinutes} min",
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(.55),
                          fontSize: 11.sp,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.05),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: Colors.white.withOpacity(.1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Cost",
                                  style: GoogleFonts.poppins(color: Colors.white.withOpacity(.5), fontSize: 10.sp),
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.diamond_rounded, color: AppColors.yellow, size: 15.sp),
                                    SizedBox(width: 4.w),
                                    Text(
                                      "${podcast.points} pts",
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "Your Balance",
                                  style: GoogleFonts.poppins(color: Colors.white.withOpacity(.5), fontSize: 10.sp),
                                ),
                                Text(
                                  "$_userPoints pts",
                                  style: GoogleFonts.poppins(
                                    color: canAfford ? const Color(0xFF4ADE80) : Colors.redAccent,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15.sp,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 18.h),
                      if (!canAfford)
                        Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.info_outline_rounded, color: Colors.redAccent, size: 14.sp),
                              SizedBox(width: 6.w),
                              Flexible(
                                child: Text(
                                  "Not enough points to unlock this episode",
                                  style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 11.sp),
                                ),
                              ),
                            ],
                          ),
                        ),
                      GestureDetector(
                        onTap: () {
                          if (!canAfford) {
                            HapticFeedback.mediumImpact();
                            return;
                          }
                          HapticFeedback.mediumImpact();
                          setState(() {
                            _userPoints -= podcast.points;
                            podcast.isOwned = true;
                          });
                          setSheetState(() {});
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("🎉 \"${podcast.title}\" unlocked!"),
                              backgroundColor: AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 15.h),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: canAfford
                                  ? [AppColors.orange, AppColors.yellow]
                                  : [Colors.white24, Colors.white12],
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: canAfford
                                ? [BoxShadow(color: AppColors.yellow.withOpacity(.5), blurRadius: 16)]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock_open_rounded,
                                  color: canAfford ? Colors.black : Colors.white38, size: 16.sp),
                              SizedBox(width: 8.w),
                              Text(
                                canAfford ? "Unlock Episode" : "Insufficient Points",
                                style: GoogleFonts.poppins(
                                  color: canAfford ? Colors.black : Colors.white38,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _userPoints);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.dark,
        body: Stack(
          children: [
            podcastsBackground(),
            const TwinklingStars(count: 26),
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(),
                    SizedBox(height: 18.h),
                    _buildCategoryHeader(),
                    SizedBox(height: 16.h),
                    _buildFilterChips(),
                    SizedBox(height: 14.h),
                    ..._filteredPodcasts.asMap().entries.map((entry) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: _podcastTile(entry.value, entry.key),
                      );
                    }),
                    if (_filteredPodcasts.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.h),
                        child: Center(
                          child: Text(
                            "No episodes in this filter yet",
                            style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12.sp),
                          ),
                        ),
                      ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.pop(context, _userPoints);
          },
          child: Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.white.withOpacity(.14), Colors.white.withOpacity(.06)],
              ),
              border: Border.all(color: Colors.white.withOpacity(.25)),
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18.sp),
          ),
        ),
        Expanded(
          child: Text(
            widget.category.title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 7.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.orange, AppColors.yellow]),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.diamond_rounded, color: Colors.black, size: 12.sp),
              SizedBox(width: 3.w),
              Text(
                "$_userPoints",
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildCategoryHeader() {
    final category = widget.category;
    return glassBox(
      padding: EdgeInsets.all(16.w),
      radius: 22.r,
      gradientColors: [category.color.withOpacity(.18), Colors.white.withOpacity(.04)],
      borderColor: category.color.withOpacity(.3),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [category.color.withOpacity(.4), category.color.withOpacity(.08)]),
              boxShadow: [BoxShadow(color: category.color.withOpacity(.4), blurRadius: 12)],
            ),
            child: Icon(category.icon, color: category.color, size: 22.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  category.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(color: Colors.white.withOpacity(.7), fontSize: 11.sp),
                ),
                SizedBox(height: 4.h),
                Text(
                  "${category.ownedCount}/${category.podcasts.length} unlocked",
                  style: GoogleFonts.poppins(
                    color: AppColors.yellow,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 80.ms, duration: 450.ms).moveY(begin: 10, end: 0);
  }

  Widget _buildFilterChips() {
    final filters = ["All", "Owned", "Locked"];
    return Row(
      children: filters.map((f) {
        final selected = _filter == f;
        return Padding(
          padding: EdgeInsets.only(right: 8.w),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _filter = f);
            },
            child: AnimatedContainer(
              duration: 250.ms,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                gradient: selected ? const LinearGradient(colors: [AppColors.orange, AppColors.yellow]) : null,
                color: selected ? null : Colors.white.withOpacity(.06),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: selected ? Colors.transparent : Colors.white.withOpacity(.12)),
              ),
              child: Text(
                f,
                style: GoogleFonts.poppins(
                  color: selected ? Colors.black : Colors.white.withOpacity(.65),
                  fontSize: 11.sp,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _podcastTile(PodcastItem podcast, int index) {
    final category = widget.category;
    return GestureDetector(
      onTap: () => _handlePodcastTap(podcast),
      child: glassBox(
        padding: EdgeInsets.all(12.w),
        radius: 18.r,
        gradientColors: podcast.isOwned
            ? [const Color(0xFF4ADE80).withOpacity(.12), Colors.white.withOpacity(.04)]
            : [Colors.white.withOpacity(.07), Colors.white.withOpacity(.03)],
        borderColor: podcast.isOwned ? const Color(0xFF4ADE80).withOpacity(.3) : Colors.white.withOpacity(.1),
        child: Row(
          children: [
            // ================= الصورة المصغّرة =================
            Container(
              width: 58.w,
              height: 58.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14.r),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [category.color.withOpacity(.5), category.color.withOpacity(.15)],
                ),
              ),
              child: Icon(
                podcast.isOwned ? Icons.play_circle_fill_rounded : category.icon,
                color: Colors.white,
                size: 26.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    podcast.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5.sp,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    "${podcast.host} • ${podcast.durationMinutes} min",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(color: Colors.white.withOpacity(.55), fontSize: 9.5.sp),
                  ),
                  SizedBox(height: 6.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: levelColor(podcast.level).withOpacity(.15),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      levelLabel(podcast.level),
                      style: GoogleFonts.poppins(
                        color: levelColor(podcast.level),
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            // ================= شارة الحالة / السعر =================
            if (podcast.isOwned)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF4ADE80).withOpacity(.15),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: const Color(0xFF4ADE80).withOpacity(.4)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: const Color(0xFF4ADE80), size: 15.sp),
                    SizedBox(height: 2.h),
                    Text(
                      "Owned",
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF4ADE80),
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.orange, AppColors.yellow]),
                  borderRadius: BorderRadius.circular(14.r),
                  boxShadow: [BoxShadow(color: AppColors.yellow.withOpacity(.4), blurRadius: 8)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.diamond_rounded, color: Colors.black, size: 13.sp),
                    SizedBox(height: 2.h),
                    Text(
                      "${podcast.points}",
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (100 + index * 70).ms, duration: 400.ms)
        .moveX(begin: 12, end: 0, curve: Curves.easeOutCubic);
  }
}