import 'dart:math' as math;

import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/data/models/question_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Student UI for PAIR — two-column tap-to-match (Duolingo-style).
///
/// UX:
/// 1. Tap a left tile, then a right tile → pair forms.
/// 2. Tap either side of an existing pair → unpair.
/// 3. Matched tiles share a highlight color and are disabled until unpaired.
///
/// Backend payload (via AnswerPayloadHelper.pair):
///   { "answer": { "pairs": { "leftId": rightId } } }
/// Correct when leftId == rightId (same pair_answers row).
class PairAnswerWidget extends StatefulWidget {
  final Question question;
  final Map<int, int>? initialPairs;
  final ValueChanged<Map<int, int>>? onChanged;
  final bool readOnly;

  const PairAnswerWidget({
    super.key,
    required this.question,
    this.initialPairs,
    this.onChanged,
    this.readOnly = false,
  });

  @override
  State<PairAnswerWidget> createState() => PairAnswerWidgetState();
}

class PairAnswerWidgetState extends State<PairAnswerWidget> {
  /// leftId → rightId
  late Map<int, int> _pairs;

  /// Stable shuffled column orders (per question id).
  late List<int> _leftOrder;
  late List<int> _rightOrder;
  late Map<int, QuestionAnswer> _byId;

  /// Currently selected side before completing a pair.
  int? _selectedLeftId;
  int? _selectedRightId;

  /// Shared accent colors for matched pairs (cycled).
  static const List<Color> _matchColors = [
    Color(0xFF2ECC71),
    Color(0xFF3498DB),
    Color(0xFFE67E22),
    Color(0xFF9B59B6),
    Color(0xFF1ABC9C),
    Color(0xFFE74C3C),
  ];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void didUpdateWidget(covariant PairAnswerWidget oldWidget) {
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

    final ids = answers.map((a) => a.id!).toList();
    _leftOrder = List<int>.from(ids)
      ..shuffle(math.Random(widget.question.id * 7919 + 17));
    _rightOrder = List<int>.from(ids)
      ..shuffle(math.Random(widget.question.id * 9973 + 42));

    final initial = widget.initialPairs;
    if (initial != null && initial.isNotEmpty) {
      _pairs = Map<int, int>.from(
        initial..removeWhere(
          (k, v) => !_byId.containsKey(k) || !_byId.containsKey(v),
        ),
      );
    } else {
      _pairs = {};
    }
    _selectedLeftId = null;
    _selectedRightId = null;
  }

  Map<int, int> get currentPairs => Map<int, int>.unmodifiable(_pairs);

  bool get isComplete => _byId.isNotEmpty && _pairs.length == _byId.length;

  void _notify() => widget.onChanged?.call(currentPairs);

  Color _colorForPair(int leftId) {
    final idx = _pairs.keys.toList().indexOf(leftId);
    if (idx < 0) return AppColors.yellow;
    return _matchColors[idx % _matchColors.length];
  }

  /// rightId → leftId reverse lookup
  int? _leftOfRight(int rightId) {
    for (final e in _pairs.entries) {
      if (e.value == rightId) return e.key;
    }
    return null;
  }

  void _onTapLeft(int id) {
    if (widget.readOnly) return;
    HapticFeedback.selectionClick();

    // Already paired → unpair
    if (_pairs.containsKey(id)) {
      setState(() {
        _pairs.remove(id);
        _selectedLeftId = null;
        _selectedRightId = null;
      });
      _notify();
      return;
    }

    // Pair with previously selected right
    if (_selectedRightId != null) {
      final rightId = _selectedRightId!;
      // Remove any existing pair that used this right
      _pairs.removeWhere((_, v) => v == rightId);
      setState(() {
        _pairs[id] = rightId;
        _selectedLeftId = null;
        _selectedRightId = null;
      });
      HapticFeedback.lightImpact();
      _notify();
      return;
    }

    // Toggle selection
    setState(() {
      _selectedLeftId = _selectedLeftId == id ? null : id;
      _selectedRightId = null;
    });
  }

  void _onTapRight(int id) {
    if (widget.readOnly) return;
    HapticFeedback.selectionClick();

    // Already paired → unpair
    final existingLeft = _leftOfRight(id);
    if (existingLeft != null) {
      setState(() {
        _pairs.remove(existingLeft);
        _selectedLeftId = null;
        _selectedRightId = null;
      });
      _notify();
      return;
    }

    // Pair with previously selected left
    if (_selectedLeftId != null) {
      final leftId = _selectedLeftId!;
      setState(() {
        _pairs[leftId] = id;
        _selectedLeftId = null;
        _selectedRightId = null;
      });
      HapticFeedback.lightImpact();
      _notify();
      return;
    }

    // Toggle selection
    setState(() {
      _selectedRightId = _selectedRightId == id ? null : id;
      _selectedLeftId = null;
    });
  }

  String _leftLabel(int id) {
    final a = _byId[id];
    return (a?.leftText ?? a?.textAnswer ?? '').trim();
  }

  String _rightLabel(int id) {
    final a = _byId[id];
    return (a?.rightText ?? a?.textAnswer ?? '').trim();
  }

  @override
  Widget build(BuildContext context) {
    if (_byId.isEmpty) {
      return Text(
        'No pairs available',
        style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13.sp),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Tap the matching pairs',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Left column ──────────────────────────────
            Expanded(
              child: Column(
                children: [
                  for (final id in _leftOrder) ...[
                    _PairTile(
                      label: _leftLabel(id),
                      selected: _selectedLeftId == id,
                      matched: _pairs.containsKey(id),
                      matchColor: _pairs.containsKey(id)
                          ? _colorForPair(id)
                          : null,
                      enabled: !widget.readOnly,
                      onTap: () => _onTapLeft(id),
                    ),
                    SizedBox(height: 10.h),
                  ],
                ],
              ),
            ),
            SizedBox(width: 12.w),
            // ── Right column ─────────────────────────────
            Expanded(
              child: Column(
                children: [
                  for (final id in _rightOrder) ...[
                    _PairTile(
                      label: _rightLabel(id),
                      selected: _selectedRightId == id,
                      matched: _leftOfRight(id) != null,
                      matchColor: _leftOfRight(id) != null
                          ? _colorForPair(_leftOfRight(id)!)
                          : null,
                      enabled: !widget.readOnly,
                      onTap: () => _onTapRight(id),
                    ),
                    SizedBox(height: 10.h),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (_pairs.isNotEmpty) ...[
          SizedBox(height: 8.h),
          Text(
            '${_pairs.length}/${_byId.length} paired',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.white38, fontSize: 11.sp),
          ),
        ],
      ],
    );
  }
}

class _PairTile extends StatelessWidget {
  final String label;
  final bool selected;
  final bool matched;
  final Color? matchColor;
  final bool enabled;
  final VoidCallback onTap;

  const _PairTile({
    required this.label,
    required this.selected,
    required this.matched,
    required this.matchColor,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor;
    final Color bgColor;
    final Color textColor;

    if (matched && matchColor != null) {
      borderColor = matchColor!;
      bgColor = matchColor!.withOpacity(0.18);
      textColor = Colors.white;
    } else if (selected) {
      borderColor = AppColors.yellow;
      bgColor = AppColors.yellow.withOpacity(0.16);
      textColor = AppColors.yellow;
    } else {
      borderColor = Colors.white.withOpacity(0.22);
      bgColor = Colors.white.withOpacity(0.06);
      textColor = Colors.white;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: borderColor,
              width: selected || matched ? 1.6 : 1,
            ),
          ),
          child: Text(
            label.isEmpty ? '—' : label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: textColor,
              fontSize: 13.sp,
              fontWeight: selected || matched
                  ? FontWeight.w600
                  : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
