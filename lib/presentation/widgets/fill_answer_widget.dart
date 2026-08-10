import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/helper/questions/fill_question_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Student UI for FILL questions — professional inline blanks.
///
/// Backend:
/// - text_question placeholders: {1}, {2}, ... sequential
/// - Student API does NOT return fill answers
/// - Submit: { "answer": { "answers": { "1": "hello", "2": "world" } } }
class FillAnswerWidget extends StatefulWidget {
  final String? textQuestion;
  final Map<int, String>? initialAnswers;
  final ValueChanged<Map<int, String>>? onChanged;
  final bool readOnly;

  const FillAnswerWidget({
    super.key,
    required this.textQuestion,
    this.initialAnswers,
    this.onChanged,
    this.readOnly = false,
  });

  @override
  State<FillAnswerWidget> createState() => FillAnswerWidgetState();
}

class FillAnswerWidgetState extends State<FillAnswerWidget> {
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, FocusNode> _focusNodes = {};
  late List<int> _orders;

  @override
  void initState() {
    super.initState();
    _rebuildControllers();
  }

  @override
  void didUpdateWidget(covariant FillAnswerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.textQuestion != widget.textQuestion) {
      _disposeControllers();
      _rebuildControllers();
    }
  }

  void _disposeControllers() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focusNodes.values) {
      f.dispose();
    }
    _controllers.clear();
    _focusNodes.clear();
  }

  void _rebuildControllers() {
    _orders = FillQuestionHelper.parseBlankOrders(widget.textQuestion);
    for (final o in _orders) {
      _controllers[o] = TextEditingController(
        text: widget.initialAnswers?[o] ?? '',
      )..addListener(_notify);
      _focusNodes[o] = FocusNode()..addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  Map<int, String> get currentAnswers {
    final map = <int, String>{};
    for (final e in _controllers.entries) {
      map[e.key] = e.value.text;
    }
    return map;
  }

  Map<String, dynamic> buildSubmitPayload() {
    return FillQuestionHelper.buildSubmitPayload(currentAnswers);
  }

  bool get isComplete =>
      _orders.isNotEmpty &&
      FillQuestionHelper.isComplete(currentAnswers, _orders);

  bool get hasNoPlaceholders => _orders.isEmpty;

  void _notify() => widget.onChanged?.call(currentAnswers);

  @override
  Widget build(BuildContext context) {
    if (_orders.isEmpty) {
      return _NoPlaceholdersCard(text: widget.textQuestion);
    }

    final segments = FillQuestionHelper.segments(widget.textQuestion);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Text.rich(
        TextSpan(
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.92),
            fontSize: 16.sp,
            height: 2.0,
            fontWeight: FontWeight.w500,
          ),
          children: [
            for (final seg in segments)
              if (seg is FillText)
                TextSpan(text: seg.text)
              else if (seg is FillBlank)
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: _DottedBlank(
                    order: seg.order,
                    controller: _controllers[seg.order]!,
                    focusNode: _focusNodes[seg.order]!,
                    readOnly: widget.readOnly,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// Inline blank: series of dots as underline; typing replaces the dots visually.
class _DottedBlank extends StatelessWidget {
  final int order;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool readOnly;

  const _DottedBlank({
    required this.order,
    required this.controller,
    required this.focusNode,
    required this.readOnly,
  });

  static const String _dots = '········';

  @override
  Widget build(BuildContext context) {
    final focused = focusNode.hasFocus;
    final hasText = controller.text.trim().isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: EdgeInsets.symmetric(horizontal: 3.w),
      constraints: BoxConstraints(minWidth: 72.w, maxWidth: 140.w),
      padding: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: focused
                ? AppColors.yellow
                : hasText
                ? AppColors.orange.withOpacity(0.85)
                : Colors.white.withOpacity(0.45),
            width: focused ? 1.8 : 1.2,
          ),
        ),
      ),
      child: IntrinsicWidth(
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          readOnly: readOnly,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
            height: 1.2,
            letterSpacing: 0.6,
          ),
          cursorColor: AppColors.yellow,
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              vertical: 2.h,
              horizontal: 2.w,
            ),
            // Series of dots only — no number hint, no box
            hintText: _dots,
            hintStyle: GoogleFonts.poppins(
              color: Colors.white.withOpacity(0.35),
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.8,
            ),
          ),
        ),
      ),
    );
  }
}

class _NoPlaceholdersCard extends StatelessWidget {
  final String? text;
  const _NoPlaceholdersCard({this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.orange.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((text ?? '').trim().isNotEmpty)
            Text(
              text!,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 15.sp,
                height: 1.5,
              ),
            ),
          SizedBox(height: 10.h),
          Text(
            'This FILL question has no {1}/{2} placeholders in text_question.',
            style: GoogleFonts.poppins(
              color: AppColors.orange,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }
}
