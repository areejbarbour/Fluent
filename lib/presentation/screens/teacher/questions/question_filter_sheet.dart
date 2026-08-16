import 'package:fluent/presentation/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/helper/questions/question_helpers.dart';

class QuestionFilterSheet extends StatefulWidget {
  final String? initialType;
  final String? initialDifficulty;
  final int? initialMinScore;
  final int? initialMaxScore;
  final String? initialSearch;
  final String? initialSort;
  final int? initialCourseId; // ✅
  final bool? initialOnlyEligible; // ✅
  final bool hideEligibleToggle; // ✅

  const QuestionFilterSheet({
    super.key,
    this.initialType,
    this.initialDifficulty,
    this.initialMinScore,
    this.initialMaxScore,
    this.initialSearch,
    this.initialSort,
    this.initialCourseId,
    this.initialOnlyEligible,
    this.hideEligibleToggle = false,
  });

  @override
  State<QuestionFilterSheet> createState() => _QuestionFilterSheetState();
}

class _QuestionFilterSheetState extends State<QuestionFilterSheet> {
  late TextEditingController _searchController;
  late TextEditingController _minScoreController;
  late TextEditingController _maxScoreController;

  String? _selectedType;
  String? _selectedDifficulty;
  String? _selectedSort;
  bool? _onlyEligible;
  int? _filterCourseId; // ✅ This will be passed from the parent screen

  final List<String> _types = ['MCQ', 'FILL', 'ARRANGE', 'PAIR'];
  final List<String> _difficulties = ['EASY', 'MEDIUM', 'HARD'];
  final List<String> _sortOptions = ['desc', 'asc'];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearch ?? '');
    _minScoreController = TextEditingController(
      text: widget.initialMinScore?.toString() ?? '',
    );
    _maxScoreController = TextEditingController(
      text: widget.initialMaxScore?.toString() ?? '',
    );
    _selectedType = widget.initialType;
    _selectedDifficulty = widget.initialDifficulty;
    _selectedSort = widget.initialSort ?? 'desc';

    _filterCourseId = widget.initialCourseId; // ✅
    _onlyEligible = widget.initialOnlyEligible ?? false; // ✅
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minScoreController.dispose();
    _maxScoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            children: [
              // Handle Bar
              Container(
                margin: EdgeInsets.only(top: 12.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              // Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                child: Row(
                  children: [
                    const Icon(
                      Icons.filter_list_rounded,
                      color: AppColors.orange,
                      size: 24,
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      "Filter Questions",
                      style: GoogleFonts.cinzelDecorative(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _clearAll,
                      child: Text(
                        "Reset",
                        style: GoogleFonts.poppins(
                          color: AppColors.sky,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSearchField(),
                      SizedBox(height: 20.h),
                      _buildTypeSelector(),
                      SizedBox(height: 20.h),
                      _buildDifficultySelector(),
                      SizedBox(height: 20.h),
                      _buildScoreRange(),
                      SizedBox(height: 20.h),
                      _buildSortSelector(),

                      // ✅ ✅ ✅ أضف السطرين التاليين هنا بالضبط ✅ ✅ ✅
                      SizedBox(height: 20.h),
                      _buildEligibilityToggle(),

                      SizedBox(height: 30.h),
                    ],
                  ),
                ),
              ),
              // Apply Button
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
                child: SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      "Apply Filters",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchField() {
    return _sectionWrapper(
      icon: Icons.search_rounded,
      title: "Search",
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 13.sp),
        decoration: _inputDecoration("Search by title (EN/AR)..."),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return _sectionWrapper(
      icon: Icons.category_rounded,
      title: "Question Type",
      child: Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: _types.map((type) {
          final isSelected = _selectedType == type;
          return _filterChip(
            label: type,
            isSelected: isSelected,
            color: QuestionUI.typeColor(type),
            onTap: () =>
                setState(() => _selectedType = isSelected ? null : type),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDifficultySelector() {
    return _sectionWrapper(
      icon: Icons.speed_rounded,
      title: "Difficulty",
      child: Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: _difficulties.map((diff) {
          final isSelected = _selectedDifficulty == diff;
          final color = diff == 'EASY'
              ? Colors.greenAccent
              : diff == 'MEDIUM'
              ? AppColors.yellow
              : Colors.redAccent;
          return _filterChip(
            label: diff,
            isSelected: isSelected,
            color: color,
            onTap: () =>
                setState(() => _selectedDifficulty = isSelected ? null : diff),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildScoreRange() {
    return _sectionWrapper(
      icon: Icons.stars_rounded,
      title: "Score Range",
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _minScoreController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 13.sp),
              textAlign: TextAlign.center,
              decoration: _inputDecoration("Min"),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Text(
              "—",
              style: GoogleFonts.poppins(
                color: Colors.white54,
                fontSize: 16.sp,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _maxScoreController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 13.sp),
              textAlign: TextAlign.center,
              decoration: _inputDecoration("Max"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortSelector() {
    return _sectionWrapper(
      icon: Icons.sort_rounded,
      title: "Sort By Date",
      child: Row(
        children: _sortOptions.map((s) {
          final isSelected = _selectedSort == s;
          final label = s == 'desc' ? 'Newest First' : 'Oldest First';
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: s == 'desc' ? 4.w : 0),
              child: _filterChip(
                label: label,
                isSelected: isSelected,
                color: AppColors.sky,
                onTap: () => setState(() => _selectedSort = s),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _applyFilters() {
    final minScore = _minScoreController.text.trim().isNotEmpty
        ? int.tryParse(_minScoreController.text.trim())
        : null;
    final maxScore = _maxScoreController.text.trim().isNotEmpty
        ? int.tryParse(_maxScoreController.text.trim())
        : null;

    if (minScore != null && maxScore != null && maxScore < minScore) {
      showAppSnackBar(
        context,
        'Max score must be ≥ min score',
        type: AppSnackType.error,
      );
      return;
    }

    // ✅ لا ترسل onlyEligible بدون courseId
    final bool? onlyEligibleToSend = (_filterCourseId != null)
        ? _onlyEligible
        : null;

    Navigator.pop(context, {
      'type': _selectedType,
      'difficulty': _selectedDifficulty,
      'min_score': minScore,
      'max_score': maxScore,
      'search': _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      'sort': _selectedSort,
      'courseId': _filterCourseId,
      'onlyEligible': onlyEligibleToSend,
    });
  }

  Widget _buildEligibilityToggle() {
    if (widget.hideEligibleToggle) return const SizedBox.shrink();

    return _sectionWrapper(
      icon: Icons.verified_user_rounded,
      title: "Eligible Questions Only",
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                "Show only questions eligible for this course",
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 12.sp,
                ),
              ),
            ),
            Switch(
              value: _onlyEligible ?? false,
              onChanged: (value) => setState(() => _onlyEligible = value),
              activeColor: AppColors.yellow,
            ),
          ],
        ),
      ),
    );
  }

  void _clearAll() {
    setState(() {
      _searchController.clear();
      _minScoreController.clear();
      _maxScoreController.clear();
      _selectedType = null;
      _selectedDifficulty = null;
      _selectedSort = 'desc';
      // لا تمسح courseId إذا جاء من سياق (اختبار كورس)
      if (!widget.hideEligibleToggle) {
        _onlyEligible = false;
      }
    });
  }

  Widget _sectionWrapper({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.orange, size: 16.sp),
            SizedBox(width: 6.w),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        child,
      ],
    );
  }

  Widget _filterChip({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.25)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isSelected ? color : Colors.white.withOpacity(0.15),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? color : Colors.white70,
            fontSize: 12.sp,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 12.sp),
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
      ),
    );
  }
}
