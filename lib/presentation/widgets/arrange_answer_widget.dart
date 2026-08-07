import 'dart:math' as math;

import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/data/models/question_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Student UI for ARRANGE — matches backend ArrangeScorer.
///
/// - Answer strip = submitted ordered_ids only
/// - Bank = all remaining tiles (including distractors) for difficulty
///
/// Payload: { "answer": { "ordered_ids": [...] } }
class ArrangeAnswerWidget extends StatefulWidget {
  final Question question;
  final List<int>? initialAnswerOrder;
  final ValueChanged<List<int>>? onChanged;
  final bool readOnly;

  const ArrangeAnswerWidget({
    super.key,
    required this.question,
    this.initialAnswerOrder,
    this.onChanged,
    this.readOnly = false,
  });

  @override
  State<ArrangeAnswerWidget> createState() => ArrangeAnswerWidgetState();
}

class ArrangeAnswerWidgetState extends State<ArrangeAnswerWidget> {
  late List<int> _answerOrder;
  late List<int> _bankIds;
  late Map<int, QuestionAnswer> _byId;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void didUpdateWidget(covariant ArrangeAnswerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id) {
      _bootstrap();
    }
  }

  void _bootstrap() {
    final answers = widget.question.answers
        .where((a) => (a.id ?? 0) > 0)
        .toList();
    _byId = {for (final a in answers) a.id!: a};

    final allIds = answers.map((a) => a.id!).toList();
    final initial = widget.initialAnswerOrder;

    if (initial != null && initial.isNotEmpty) {
      final valid = initial.where(_byId.containsKey).toList();
      _answerOrder = List<int>.from(valid);
      _bankIds = allIds.where((id) => !_answerOrder.contains(id)).toList();
    } else {
      _answerOrder = [];
      _bankIds = List<int>.from(allIds)
        ..shuffle(math.Random(widget.question.id * 104729 + 13));
    }
  }

  List<int> get currentOrderedIds => List<int>.unmodifiable(_answerOrder);
  bool get isComplete => _answerOrder.isNotEmpty;
  bool get hasTiles => _byId.isNotEmpty;

  void _notify() => widget.onChanged?.call(currentOrderedIds);

  void _addToAnswer(int id) {
    if (widget.readOnly) return;
    if (!_bankIds.contains(id)) return;
    HapticFeedback.selectionClick();
    setState(() {
      _bankIds.remove(id);
      _answerOrder.add(id);
    });
    _notify();
  }

  void _removeFromAnswer(int id) {
    if (widget.readOnly) return;
    if (!_answerOrder.contains(id)) return;
    HapticFeedback.selectionClick();
    setState(() {
      _answerOrder.remove(id);
      _bankIds.add(id);
    });
    _notify();
  }

  void _onReorderAnswer(int oldIndex, int newIndex) {
    if (widget.readOnly) return;
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final id = _answerOrder.removeAt(oldIndex);
      _answerOrder.insert(newIndex, id);
    });
    _notify();
  }

  String _label(int id) => _byId[id]?.textAnswer ?? '#$id';

  @override
  Widget build(BuildContext context) {
    if (!hasTiles) {
      return _EmptyHint(text: 'No arrange items for this question.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionLabel(
          icon: Icons.format_list_numbered_rounded,
          title: 'Your sequence',
          subtitle: 'Tap bank tiles to add · drag to reorder · tap X to remove',
        ),
        SizedBox(height: 10.h),
        _AnswerStrip(
          orderedIds: _answerOrder,
          labelOf: _label,
          readOnly: widget.readOnly,
          onReorder: _onReorderAnswer,
          onRemove: _removeFromAnswer,
        ),
        SizedBox(height: 18.h),
        _SectionLabel(
          icon: Icons.grid_view_rounded,
          title: 'Word bank',
          subtitle: _bankIds.isEmpty
              ? 'All tiles are in your sequence'
              : 'Extra / wrong tiles stay here — do not add them to the sequence',
        ),
        SizedBox(height: 10.h),
        _BankWrap(
          bankIds: _bankIds,
          labelOf: _label,
          readOnly: widget.readOnly,
          onTap: _addToAnswer,
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionLabel({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.sky, size: 16.sp),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  color: Colors.white54,
                  fontSize: 10.5.sp,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnswerStrip extends StatelessWidget {
  final List<int> orderedIds;
  final String Function(int id) labelOf;
  final bool readOnly;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(int id) onRemove;

  const _AnswerStrip({
    required this.orderedIds,
    required this.labelOf,
    required this.readOnly,
    required this.onReorder,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (orderedIds.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 22.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.yellow.withOpacity(0.28)),
        ),
        child: Text(
          'Build the correct order here.\nLeave extra / wrong tiles in the bank.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.white38,
            fontSize: 12.sp,
            height: 1.45,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(8.w, 10.h, 8.w, 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.sky.withOpacity(0.28)),
      ),
      child: ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: orderedIds.length,
        onReorder: readOnly ? (_, __) {} : onReorder,
        itemBuilder: (context, index) {
          final id = orderedIds[index];
          return _AnswerTile(
            key: ValueKey('answer-$id'),
            index: index,
            text: labelOf(id),
            readOnly: readOnly,
            onRemove: () => onRemove(id),
          );
        },
      ),
    );
  }
}

class _AnswerTile extends StatelessWidget {
  final int index;
  final String text;
  final bool readOnly;
  final VoidCallback onRemove;

  const _AnswerTile({
    super.key,
    required this.index,
    required this.text,
    required this.readOnly,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.yellow.withOpacity(0.16),
            Colors.white.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.yellow.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          if (!readOnly)
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: Icon(
                  Icons.drag_handle_rounded,
                  color: Colors.white54,
                  size: 20.sp,
                ),
              ),
            )
          else
            SizedBox(width: 4.w),
          Container(
            width: 24.w,
            height: 24.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.yellow.withOpacity(0.25),
              borderRadius: BorderRadius.circular(7.r),
            ),
            child: Text(
              '${index + 1}',
              style: GoogleFonts.poppins(
                color: AppColors.yellow,
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!readOnly)
            GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.white54,
                  size: 18.sp,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BankWrap extends StatelessWidget {
  final List<int> bankIds;
  final String Function(int id) labelOf;
  final bool readOnly;
  final void Function(int id) onTap;

  const _BankWrap({
    required this.bankIds,
    required this.labelOf,
    required this.readOnly,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (bankIds.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 14.h),
        alignment: Alignment.center,
        child: Text(
          'Bank is empty',
          style: GoogleFonts.poppins(color: Colors.white30, fontSize: 12.sp),
        ),
      );
    }

    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        for (final id in bankIds)
          GestureDetector(
            onTap: readOnly ? null : () => onTap(id),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: readOnly ? 0.55 : 1,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.white.withOpacity(0.14)),
                ),
                child: Text(
                  labelOf(id),
                  style: GoogleFonts.poppins(
                    color: Colors.white.withOpacity(0.92),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.orange.withOpacity(0.35)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(color: AppColors.orange, fontSize: 12.sp),
      ),
    );
  }
}
