

import 'dart:math' as math;
import 'dart:ui';

import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/cubit/student/podcasts/open_podcast_cubit.dart';
import 'package:fluent/cubit/student/podcasts/open_podcast_state.dart';
import 'package:fluent/cubit/student/podcasts/podcast_topics_cubit.dart';
import 'package:fluent/cubit/student/podcasts/podcast_topics_state.dart';
import 'package:fluent/cubit/student/podcasts/topic_podcasts_cubit.dart';
import 'package:fluent/cubit/student/podcasts/topic_podcasts_state.dart';
import 'package:fluent/data/models/podcast_model.dart';
import 'package:fluent/data/repository/podcast_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluent/constants/strings.dart';


enum PodcastLevel { beginner, intermediate, advanced }

class PodcastItem {
  final int? id;
  final String title;
  final String host;
  final int durationMinutes;
  final int points;
  final PodcastLevel level;
  bool isOwned;

  PodcastItem({
    this.id,
    required this.title,
    required this.host,
    required this.durationMinutes,
    required this.points,
    required this.level,
    this.isOwned = false,
  });
}

class PodcastCategory {
  final int? id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? imageUrl;
  final List<PodcastItem> podcasts;

  const PodcastCategory({
    this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.imageUrl,
    required this.podcasts,
  });

  int get ownedCount => podcasts.where((p) => p.isOwned).length;
}

const List<IconData> _topicIcons = [
  Icons.business_center_rounded,
  Icons.flight_takeoff_rounded,
  Icons.chat_bubble_rounded,
  Icons.menu_book_rounded,
  Icons.auto_stories_rounded,
  Icons.newspaper_rounded,
  Icons.science_rounded,
  Icons.sports_esports_rounded,
];

const List<Color> _topicColors = [
  AppColors.sky,
  AppColors.orange,
  AppColors.yellow,
  Color(0xffB388FF),
  Color(0xffFF6FB5),
  Color(0xFF4ADE80),
  Color(0xff36D1C4),
  Color(0xffFF8FD9),
];

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
            .move(
              begin: Offset.zero,
              end: const Offset(-15, 10),
              duration: 5500.ms,
              curve: Curves.easeInOut,
            ),
      ),
      Positioned(
        top: 420.h,
        left: -100.w,
        child: _glowCircle(AppColors.sky, 260.w, 150, 30)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .move(
              begin: Offset.zero,
              end: const Offset(20, 15),
              duration: 6500.ms,
              curve: Curves.easeInOut,
            ),
      ),
      Positioned(
        top: 850.h,
        right: -60.w,
        child: _glowCircle(const Color(0xffB861F5), 220.w, 140, 25)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .move(
              begin: Offset.zero,
              end: const Offset(-10, -8),
              duration: 7000.ms,
              curve: Curves.easeInOut,
            ),
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
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.30),
          blurRadius: blur,
          spreadRadius: spread,
        ),
      ],
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
                    ? [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.7),
                          blurRadius: 4,
                          spreadRadius: 0.5,
                        ),
                      ]
                    : null,
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .fade(
                  begin: 0,
                  end: maxOpacity,
                  duration: duration.ms,
                  delay: delay.ms,
                )
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
            colors: gradientColors ??
                [
                  Colors.white.withOpacity(.10),
                  Colors.white.withOpacity(.04),
                ],
          ),
          border: Border.all(
            color: borderColor ?? Colors.white.withOpacity(.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
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

PodcastCategory _mapTopic(PodcastTopicModel t, int index) {
  return PodcastCategory(
    id: t.id,
    title: t.name,
    subtitle: "Explore this topic",
    icon: _topicIcons[index % _topicIcons.length],
    color: _topicColors[index % _topicColors.length],
    imageUrl: t.imageUrl,
    podcasts: const [],
  );
}

List<PodcastItem> _mapTopicPodcasts(TopicPodcastsModel data) {
  final list = <PodcastItem>[];

  for (final p in data.openedPodcasts) {
    list.add(
      PodcastItem(
        id: p.id,
        title: p.name,
        host: "Podcast",
        durationMinutes: 10,
        points: p.pointRequired,
        level: PodcastLevel.intermediate,
        isOwned: true,
      ),
    );
  }

  for (final p in data.lockedPodcasts) {
    list.add(
      PodcastItem(
        id: p.id,
        title: p.name,
        host: "Podcast",
        durationMinutes: 10,
        points: p.pointRequired,
        level: PodcastLevel.intermediate,
        isOwned: false,
      ),
    );
  }

  return list;
}

// ─────────────────────────────────────────────
// PodcastsScreen
// ─────────────────────────────────────────────

class PodcastsScreen extends StatefulWidget {
  const PodcastsScreen({super.key});

  @override
  State<PodcastsScreen> createState() => _PodcastsScreenState();
}

class _PodcastsScreenState extends State<PodcastsScreen> {
  int _userPoints = 450;

  Future<void> _openCategory(PodcastCategory category) async {
    if (category.id == null) return;
    HapticFeedback.selectionClick();

    final updatedPoints = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (ctx) => TopicPodcastsCubit(ctx.read<PodcastRepository>())
                ..fetchTopicPodcasts(category.id!),
            ),
            BlocProvider(
              create: (ctx) =>
                  OpenPodcastCubit(ctx.read<PodcastRepository>()),
            ),
          ],
          child: PodcastListScreen(
            category: category,
            userPoints: _userPoints,
          ),
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
            child: BlocBuilder<PodcastTopicsCubit, PodcastTopicsState>(
              builder: (context, state) {
                if (state is PodcastTopicsLoading ||
                    state is PodcastTopicsInitial) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.yellow),
                  );
                }

                if (state is PodcastTopicsFailure) {
                  return _buildError(state.message);
                }

                final topics = state is PodcastTopicsSuccess
                    ? state.topics
                        .asMap()
                        .entries
                        .map((e) => _mapTopic(e.value, e.key))
                        .toList()
                    : <PodcastCategory>[];

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopBar(),
                      SizedBox(height: 18.h),
                      _buildIntroBanner(topics),
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
                      if (topics.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 40.h),
                          child: Center(
                            child: Text(
                              "No topics available yet",
                              style: GoogleFonts.poppins(
                                color: Colors.white38,
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                        )
                      else
                        _buildCategoriesGrid(topics),
                      SizedBox(height: 20.h),
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

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                color: Colors.white.withOpacity(.6), size: 40.sp),
            SizedBox(height: 12.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(.8),
                fontSize: 13.sp,
              ),
            ),
            SizedBox(height: 16.h),
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                context.read<PodcastTopicsCubit>().fetchTopics();
              },
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.orange, AppColors.yellow],
                  ),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Text(
                  "Retry",
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.sp,
                  ),
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
        _circleIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.pop(context),
        ),
        Expanded(
          child: Text(
            "Podcasts",
            textAlign: TextAlign.center,
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

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
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
            colors: [
              Colors.white.withOpacity(.14),
              Colors.white.withOpacity(.06),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(.25)),
        ),
        child: Icon(icon, color: Colors.white, size: 18.sp),
      ),
    );
  }

  Widget _buildIntroBanner(List<PodcastCategory> topics) {
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
              boxShadow: [
                BoxShadow(
                  color: AppColors.yellow.withOpacity(.5),
                  blurRadius: 14,
                ),
              ],
            ),
            child: Icon(
              Icons.headset_rounded,
              color: Colors.black,
              size: 22.sp,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Listen & Learn",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  "${topics.length} topics available",
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(.6),
                    fontSize: 10.5.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.orange, AppColors.yellow],
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.yellow.withOpacity(.5),
                  blurRadius: 10,
                ),
              ],
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

  Widget _buildCategoriesGrid(List<PodcastCategory> categories) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 0.92,
      ),
      itemBuilder: (context, i) {
        final category = categories[i];
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(14.r),
                  child: category.imageUrl != null &&
                          category.imageUrl!.trim().isNotEmpty
                      ? Image.network(
                          category.imageUrl!,
                          width: 48.w,
                          height: 48.w,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _topicIconBox(category),
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return SizedBox(
                              width: 48.w,
                              height: 48.w,
                              child: Center(
                                child: SizedBox(
                                  width: 18.w,
                                  height: 18.w,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: category.color,
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : _topicIconBox(category),
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
                    Icon(
                      Icons.podcasts_rounded,
                      color: Colors.white38,
                      size: 12.sp,
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        "Tap to explore",
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(.5),
                          fontSize: 9.sp,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: category.color,
                      size: 10.sp,
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (100 + index * 70).ms, duration: 450.ms)
        .scale(
          begin: const Offset(.9, .9),
          end: const Offset(1, 1),
          curve: Curves.easeOutBack,
        );
  }

  Widget _topicIconBox(PodcastCategory category) {
    return Container(
      width: 48.w,
      height: 48.w,
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        gradient: RadialGradient(
          colors: [
            category.color.withOpacity(.4),
            category.color.withOpacity(.08),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: category.color.withOpacity(.4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Icon(
        category.icon,
        color: category.color,
        size: 22.sp,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PodcastListScreen
// ─────────────────────────────────────────────

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
  String _filter = "All";

  List<PodcastItem> _filterList(List<PodcastItem> all) {
    switch (_filter) {
      case "Owned":
        return all.where((p) => p.isOwned).toList();
      case "Locked":
        return all.where((p) => !p.isOwned).toList();
      default:
        return all;
    }
  }

  void _handlePodcastTap(PodcastItem podcast) {
  if (podcast.isOwned) {
    HapticFeedback.lightImpact();
    if (podcast.id == null) return;
    Navigator.pushNamed(
      context,
      podcastDetailRoute,
      arguments: {
        'podcastId': podcast.id,
        'title': podcast.title,
      },
    );
    return;
  }
  _showPurchaseSheet(podcast);
}

  // void _handlePodcastTap(PodcastItem podcast) {
  //   if (podcast.isOwned) {
  //     HapticFeedback.lightImpact();
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text("▶ Playing \"${podcast.title}\"..."),
  //         backgroundColor: AppColors.primary,
  //         behavior: SnackBarBehavior.floating,
  //         duration: const Duration(seconds: 1),
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(12.r),
  //         ),
  //       ),
  //     );
  //     return;
  //   }
  //   _showPurchaseSheet(podcast);
  // }

  void _showPurchaseSheet(PodcastItem podcast) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return BlocProvider.value(
          value: context.read<OpenPodcastCubit>(),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              final canAfford = _userPoints >= podcast.points;
              return ClipRRect(
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(28.r)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 26.h),
                    decoration: BoxDecoration(
                      color: AppColors.dark.withOpacity(.92),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(28.r)),
                      border: Border(
                        top: BorderSide(color: Colors.white.withOpacity(.12)),
                      ),
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
                              colors: [
                                widget.category.color.withOpacity(.4),
                                widget.category.color.withOpacity(.08),
                              ],
                            ),
                          ),
                          child: Icon(
                            Icons.podcasts_rounded,
                            color: widget.category.color,
                            size: 30.sp,
                          ),
                        ),
                        SizedBox(height: 14.h),
                        Text(
                          podcast.title,
                          textAlign: TextAlign.center,
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
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 14.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.05),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: Colors.white.withOpacity(.1),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Cost",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white.withOpacity(.5),
                                      fontSize: 10.sp,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.diamond_rounded,
                                        color: AppColors.yellow,
                                        size: 15.sp,
                                      ),
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
                                    style: GoogleFonts.poppins(
                                      color: Colors.white.withOpacity(.5),
                                      fontSize: 10.sp,
                                    ),
                                  ),
                                  Text(
                                    "$_userPoints pts",
                                    style: GoogleFonts.poppins(
                                      color: canAfford
                                          ? const Color(0xFF4ADE80)
                                          : Colors.redAccent,
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
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: Colors.redAccent,
                                  size: 14.sp,
                                ),
                                SizedBox(width: 6.w),
                                Flexible(
                                  child: Text(
                                    "Not enough points to unlock this episode",
                                    style: GoogleFonts.poppins(
                                      color: Colors.redAccent,
                                      fontSize: 11.sp,
                                    ),
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
                            if (podcast.id == null) return;

                            HapticFeedback.mediumImpact();
                            Navigator.pop(sheetContext);

                            context
                                .read<OpenPodcastCubit>()
                                .openPodcast(podcast.id!);
                          },
                          child: BlocBuilder<OpenPodcastCubit, OpenPodcastState>(
                            builder: (context, openState) {
                              final isLoading =
                                  openState is OpenPodcastLoading &&
                                      openState.podcastId == podcast.id;

                              return Container(
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
                                      ? [
                                          BoxShadow(
                                            color: AppColors.yellow
                                                .withOpacity(.5),
                                            blurRadius: 16,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (isLoading)
                                      SizedBox(
                                        width: 18.w,
                                        height: 18.w,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black,
                                        ),
                                      )
                                    else ...[
                                      Icon(
                                        Icons.lock_open_rounded,
                                        color: canAfford
                                            ? Colors.black
                                            : Colors.white38,
                                        size: 16.sp,
                                      ),
                                      SizedBox(width: 8.w),
                                      Text(
                                        canAfford
                                            ? "Unlock Episode"
                                            : "Insufficient Points",
                                        style: GoogleFonts.poppins(
                                          color: canAfford
                                              ? Colors.black
                                              : Colors.white38,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13.sp,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
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
      child: BlocListener<OpenPodcastCubit, OpenPodcastState>(
        listener: (context, state) {
  if (state is OpenPodcastSuccess) {
    setState(() {
      _userPoints = state.result.remainingPoints;
    });
    if (widget.category.id != null) {
      context
          .read<TopicPodcastsCubit>()
          .fetchTopicPodcasts(widget.category.id!);
    }

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
                state.result.message,
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
    context.read<OpenPodcastCubit>().reset();
  } else if (state is OpenPodcastFailure) {
    HapticFeedback.mediumImpact();
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
                Icons.error_outline_rounded,
                color: Colors.redAccent,
                size: 18.sp,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                state.message,
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
    context.read<OpenPodcastCubit>().reset();
  }
},
        child: Scaffold(
          backgroundColor: AppColors.dark,
          body: Stack(
            children: [
              podcastsBackground(),
              const TwinklingStars(count: 26),
              SafeArea(
                child: BlocBuilder<TopicPodcastsCubit, TopicPodcastsState>(
                  builder: (context, state) {
                    if (state is TopicPodcastsLoading ||
                        state is TopicPodcastsInitial) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.yellow,
                        ),
                      );
                    }

                    if (state is TopicPodcastsFailure) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32.w),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                state.message,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 13.sp,
                                ),
                              ),
                              SizedBox(height: 14.h),
                              GestureDetector(
                                onTap: () {
                                  if (widget.category.id != null) {
                                    context
                                        .read<TopicPodcastsCubit>()
                                        .fetchTopicPodcasts(
                                          widget.category.id!,
                                        );
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 18.w,
                                    vertical: 10.h,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppColors.orange,
                                        AppColors.yellow,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(14.r),
                                  ),
                                  child: Text(
                                    "Retry",
                                    style: GoogleFonts.poppins(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.sp,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final allPodcasts = state is TopicPodcastsSuccess
                        ? _mapTopicPodcasts(state.data)
                        : <PodcastItem>[];
                    final filtered = _filterList(allPodcasts);
                    final ownedCount =
                        allPodcasts.where((p) => p.isOwned).length;

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 10.h,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTopBar(),
                          SizedBox(height: 18.h),
                          _buildCategoryHeader(
                            ownedCount,
                            allPodcasts.length,
                          ),
                          SizedBox(height: 16.h),
                          _buildFilterChips(),
                          SizedBox(height: 14.h),
                          ...filtered.asMap().entries.map((entry) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: 12.h),
                              child: _podcastTile(entry.value, entry.key),
                            );
                          }),
                          if (filtered.isEmpty)
  Padding(
    padding: EdgeInsets.symmetric(vertical: 48.h),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68.w,
            height: 68.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.category.color.withOpacity(.12),
              border: Border.all(
                color: widget.category.color.withOpacity(.35),
                width: 1.5,
              ),
            ),
            child: Icon(
              _filter == "Locked"
                  ? Icons.lock_rounded
                  : _filter == "Owned"
                      ? Icons.lock_open_rounded
                      : Icons.podcasts_rounded,
              color: widget.category.color.withOpacity(.75),
              size: 28.sp,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Nothing here yet',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            _filter == "Locked"
                ? 'No locked episodes to show'
                : _filter == "Owned"
                    ? 'No unlocked episodes yet'
                    : 'No episodes available in this topic',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.45),
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms),
  ),
                          SizedBox(height: 20.h),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
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
                colors: [
                  Colors.white.withOpacity(.14),
                  Colors.white.withOpacity(.06),
                ],
              ),
              border: Border.all(color: Colors.white.withOpacity(.25)),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18.sp,
            ),
          ),
        ),
        Expanded(
          child: Text(
            widget.category.title,
            textAlign: TextAlign.center,
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
            gradient: const LinearGradient(
              colors: [AppColors.orange, AppColors.yellow],
            ),
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

  Widget _buildCategoryHeader(int ownedCount, int total) {
    final category = widget.category;
    return glassBox(
      padding: EdgeInsets.all(16.w),
      radius: 22.r,
      gradientColors: [
        category.color.withOpacity(.18),
        Colors.white.withOpacity(.04),
      ],
      borderColor: category.color.withOpacity(.3),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  category.color.withOpacity(.4),
                  category.color.withOpacity(.08),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: category.color.withOpacity(.4),
                  blurRadius: 12,
                ),
              ],
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
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(.7),
                    fontSize: 11.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  "$ownedCount/$total unlocked",
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
                gradient: selected
                    ? const LinearGradient(
                        colors: [AppColors.orange, AppColors.yellow],
                      )
                    : null,
                color: selected ? null : Colors.white.withOpacity(.06),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: selected
                      ? Colors.transparent
                      : Colors.white.withOpacity(.12),
                ),
              ),
              child: Text(
                f,
                style: GoogleFonts.poppins(
                  color: selected
                      ? Colors.black
                      : Colors.white.withOpacity(.65),
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
    final isLocked = !podcast.isOwned;

    return GestureDetector(
          onTap: () => _handlePodcastTap(podcast),
          child: glassBox(
            padding: EdgeInsets.all(12.w),
            radius: 18.r,
            gradientColors: isLocked
                ? [
                    Colors.white.withOpacity(.07),
                    Colors.white.withOpacity(.03),
                  ]
                : [
                    const Color(0xFF4ADE80).withOpacity(.12),
                    Colors.white.withOpacity(.04),
                  ],
            borderColor: isLocked
                ? Colors.white.withOpacity(.1)
                : const Color(0xFF4ADE80).withOpacity(.3),
            child: Row(
              children: [
Stack(
  clipBehavior: Clip.none,
  children: [
    Container(
      width: 58.w,
      height: 58.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLocked
              ? [
                  Colors.white.withOpacity(.10),
                  Colors.white.withOpacity(.04),
                ]
              : [
                  category.color.withOpacity(.55),
                  category.color.withOpacity(.22),
                ],
        ),
        border: Border.all(
          color: isLocked
              ? Colors.white.withOpacity(.12)
              : category.color.withOpacity(.45),
        ),
        boxShadow: isLocked
            ? null
            : [
                BoxShadow(
                  color: category.color.withOpacity(.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // دائرة خلفية ناعمة
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(isLocked ? .06 : .12),
            ),
          ),
          Icon(
            isLocked
                ? Icons.podcasts_rounded
                : Icons.play_circle_fill_rounded,
            color: isLocked
                ? Colors.white.withOpacity(.45)
                : Colors.white,
            size: 28.sp,
          ),
        ],
      ),
    ),
    if (isLocked)
      Positioned(
        right: -4.w,
        bottom: -4.h,
        child: Container(
          width: 22.w,
          height: 22.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.dark,
            border: Border.all(
              color: Colors.white.withOpacity(.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.35),
                blurRadius: 6,
              ),
            ],
          ),
          child: Icon(
            Icons.lock_rounded,
            color: AppColors.yellow,
            size: 12.sp,
          ),
        ),
      ),
  ],
),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        podcast.title,
                        style: GoogleFonts.poppins(
                          color:
                              Colors.white.withOpacity(isLocked ? .75 : 1),
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5.sp,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        isLocked
                            ? "Locked • ${podcast.points} pts required"
                            : "Unlocked • Ready to play",
                        style: GoogleFonts.poppins(
                          color: Colors.white.withOpacity(.55),
                          fontSize: 9.5.sp,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 7.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: (isLocked
                                  ? AppColors.yellow
                                  : const Color(0xFF4ADE80))
                              .withOpacity(.15),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          isLocked ? "Locked" : "Opened",
                          style: GoogleFonts.poppins(
                            color: isLocked
                                ? AppColors.yellow
                                : const Color(0xFF4ADE80),
                            fontSize: 8.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                if (!isLocked)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ADE80).withOpacity(.15),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: const Color(0xFF4ADE80).withOpacity(.4),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_open_rounded,
                          color: const Color(0xFF4ADE80),
                          size: 15.sp,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          "Open",
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
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.orange, AppColors.yellow],
                      ),
                      borderRadius: BorderRadius.circular(14.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.yellow.withOpacity(.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_rounded,
                          color: Colors.black,
                          size: 13.sp,
                        ),
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