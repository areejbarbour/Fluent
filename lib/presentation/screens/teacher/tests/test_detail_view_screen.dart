import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/data/models/question_model.dart';
import 'package:fluent/data/models/test_model.dart';
import 'package:fluent/data/repository/test_repository.dart';
import 'package:fluent/helper/questions/question_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// شاشة عرض فقط لتفاصيل الاختبار + أسئلته
/// مصدر البيانات: GET /api/tests/{id}
class TestDetailViewScreen extends StatefulWidget {
  final int testId;

  const TestDetailViewScreen({super.key, required this.testId});

  @override
  State<TestDetailViewScreen> createState() => _TestDetailViewScreenState();
}

class _TestDetailViewScreenState extends State<TestDetailViewScreen> {
  bool _loading = true;
  String? _error;
  TestModel? _test;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repo = context.read<TestRepository>();
      final result = await repo.getTestById(widget.testId);

      if (!mounted) return;

      if (result['success'] == true && result['data'] is TestModel) {
        setState(() {
          _test = result['data'] as TestModel;
          _loading = false;
        });
      } else {
        setState(() {
          _error = result['message']?.toString() ?? 'Failed to load test';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: QuestionUI.backgroundGradient()),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20.sp,
            ),
          ),
          Expanded(
            child: Text(
              'Test Details',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: Colors.white24),
            ),
            child: Text(
              'View only',
              style: GoogleFonts.poppins(
                color: Colors.white54,
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.yellow),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.redAccent, size: 48.sp),
              SizedBox(height: 12.h),
              Text(
                _error!,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 13.sp,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.yellow,
                  foregroundColor: AppColors.dark,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final test = _test!;
    return RefreshIndicator(
      color: AppColors.yellow,
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 32.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTestInfo(test),
            SizedBox(height: 24.h),
            _buildQuestionsSection(test.questions),
          ],
        ),
      ),
    );
  }

  Widget _buildTestInfo(TestModel test) {
    final statusColor = _statusColor(test.status);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.10),
            Colors.white.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: statusColor.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.quiz_outlined, color: AppColors.sky, size: 18.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Test Information',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _badge(test.status, statusColor),
            ],
          ),
          SizedBox(height: 14.h),
          _row('Title (EN)', test.titleEn.isNotEmpty ? test.titleEn : '—'),
          _row('Title (AR)', test.titleAr.isNotEmpty ? test.titleAr : '—'),
          _row('Passing Score', '${test.passingScore}%'),
          _row('Type', test.testableType),
          _row('Questions', '${test.questions.length}'),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110.w,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white54,
                fontSize: 12.sp,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsSection(List<Question> questions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.help_outline, color: AppColors.yellow, size: 18.sp),
            SizedBox(width: 8.w),
            Text(
              'Questions (${questions.length})',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        if (questions.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 32.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                Icon(Icons.inbox_outlined, color: Colors.white38, size: 40.sp),
                SizedBox(height: 8.h),
                Text(
                  'No questions in this test',
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          )
        else
          ...questions.asMap().entries.map(
            (e) => _buildQuestionCard(e.key + 1, e.value),
          ),
      ],
    );
  }

  Widget _buildQuestionCard(int index, Question q) {
    final typeLabel = q.type.toString().split('.').last;
    final diffLabel = q.difficulty.toString().split('.').last;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.09),
            Colors.white.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.sky.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28.w,
                height: 28.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.yellow.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '$index',
                  style: GoogleFonts.poppins(
                    color: AppColors.yellow,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.sp,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  q.titleQuestionEn.isNotEmpty
                      ? q.titleQuestionEn
                      : (q.titleQuestionAr.isNotEmpty
                            ? q.titleQuestionAr
                            : 'Question #$index'),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (q.titleQuestionAr.isNotEmpty && q.titleQuestionEn.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              q.titleQuestionAr,
              style: GoogleFonts.poppins(
                color: Colors.white54,
                fontSize: 11.sp,
              ),
            ),
          ],
          if (q.textQuestion != null && q.textQuestion!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              q.textQuestion!,
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12.sp,
              ),
            ),
          ],
          SizedBox(height: 10.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: [
              _chip(typeLabel, AppColors.sky),
              _chip(diffLabel, AppColors.orange),
              _chip('${q.score} pts', AppColors.yellow),
            ],
          ),
          if (q.answers.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(
              'Answers (${q.answers.length})',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 6.h),
            ...q.answers.map((a) => _answerRow(a)),
          ],
        ],
      ),
    );
  }

  Widget _answerRow(QuestionAnswer a) {
    final isCorrect = a.isCorrect == true || a.isCorrect == 1;
    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isCorrect
            ? Colors.greenAccent.withOpacity(0.12)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isCorrect
              ? Colors.greenAccent.withOpacity(0.4)
              : Colors.white12,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCorrect ? Icons.check_circle : Icons.circle_outlined,
            size: 16.sp,
            color: isCorrect ? Colors.greenAccent : Colors.white38,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              _answerText(a),
              style: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _answerText(QuestionAnswer a) {
    if (a.textAnswer != null && a.textAnswer!.isNotEmpty) {
      return a.textAnswer!;
    }
    if (a.leftText != null || a.rightText != null) {
      return '${a.leftText ?? '—'}  ↔  ${a.rightText ?? '—'}';
    }
    return '—';
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _badge(String status, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'published':
        return Colors.greenAccent;
      case 'pending':
        return AppColors.lightOrange;
      case 'draft':
        return Colors.white70;
      case 'in_review':
        return AppColors.sky;
      case 'changes_requested':
        return Colors.redAccent;
      case 'approved':
        return Colors.tealAccent;
      case 'archived':
        return Colors.purpleAccent;
      case 'closed':
        return Colors.blueGrey;
      default:
        return Colors.white54;
    }
  }
}
