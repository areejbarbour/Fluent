import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/cubit/teacher/questions/create/question_create_cubit.dart';
import 'package:fluent/cubit/teacher/questions/create/question_create_state.dart';
import 'package:fluent/cubit/teacher/questions/detail/question_detail_cubit.dart';
import 'package:fluent/cubit/teacher/questions/detail/question_detail_state.dart';
import 'package:fluent/cubit/teacher/questions/update/question_update_cubit.dart';
import 'package:fluent/cubit/teacher/questions/update/question_update_state.dart';
import 'package:fluent/data/models/question_model.dart';
import 'package:fluent/data/models/question_type.dart';
import 'package:fluent/data/repository/question_repository.dart';
import 'package:fluent/helper/questions/question_helpers.dart';
import 'package:fluent/presentation/widgets/audio_preview_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class QuestionFormScreen extends StatelessWidget {
  final int? questionId;
  const QuestionFormScreen({super.key, this.questionId});
  bool get isEdit => questionId != null;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (ctx) => QuestionCreateCubit(ctx.read<QuestionRepository>()),
        ),
        BlocProvider(
          create: (ctx) => QuestionUpdateCubit(ctx.read<QuestionRepository>()),
        ),
        if (isEdit)
          BlocProvider(
            create: (ctx) =>
                QuestionDetailCubit(ctx.read<QuestionRepository>())
                  ..loadQuestion(questionId!),
          ),
      ],
      child: _FormView(questionId: questionId),
    );
  }
}

class _FormView extends StatefulWidget {
  final int? questionId;
  const _FormView({this.questionId});

  @override
  State<_FormView> createState() => _FormViewState();
}

class _FormViewState extends State<_FormView> {
  final _formKey = GlobalKey<FormState>();
  final _titleEn = TextEditingController();
  final _titleAr = TextEditingController();
  final _textQuestion = TextEditingController();
  final _scoreController = TextEditingController(text: '1');
  QuestionType _type = QuestionType.mcq;
  QuestionDifficulty _difficulty = QuestionDifficulty.easy;
  int _score = 1;
  File? _audioFile;
  File? _imageFile;
  String? _audioFileName;
  String? _imageFileName;
  String? _existingImageUrl;
  String? _existingAudioUrl;
  List<_AnswerDraft> _answers = [];
  bool _prefilled = false;

  @override
  void dispose() {
    _titleEn.dispose();
    _titleAr.dispose();
    _textQuestion.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  void _resetAnswersForType(QuestionType type) {
    switch (type) {
      case QuestionType.mcq:
        _answers = List.generate(
          3,
          (_) => _AnswerDraft(text: '', isCorrect: false),
        );
        break;
      case QuestionType.fill:
        _answers = List.generate(
          2,
          (_) => _AnswerDraft(text: '', blankOrder: 0),
        );
        break;
      case QuestionType.arrange:
        _answers = List.generate(
          3,
          (_) => _AnswerDraft(text: '', isCorrect: false, order: 0),
        );
        break;
      case QuestionType.pair:
        _answers = List.generate(3, (_) => _AnswerDraft(left: '', right: ''));
        break;
    }
  }

  void _prefillFromEdit(Question q) {
    if (_prefilled) return;
    _prefilled = true;
    _titleEn.text = q.titleQuestionEn;
    _titleAr.text = q.titleQuestionAr;
    _textQuestion.text = q.textQuestion ?? '';
    _type = q.type;
    _difficulty = q.difficulty;
    _score = q.score;
    _scoreController.text = _score.toString();
    _existingImageUrl = (q.imageUrl != null && q.imageUrl!.isNotEmpty)
        ? q.imageUrl
        : null;
    _existingAudioUrl = (q.audioUrl != null && q.audioUrl!.isNotEmpty)
        ? q.audioUrl
        : null;
    _answers = q.answers.map((a) {
      return _AnswerDraft(
        text: a.textAnswer ?? '',
        isCorrect: a.isCorrect ?? false,
        order: a.order ?? 0,
        blankOrder: a.blankOrder ?? 0,
        left: a.leftText ?? '',
        right: a.rightText ?? '',
      );
    }).toList();
    if (_answers.isEmpty) _resetAnswersForType(_type);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.questionId != null;
    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: QuestionUI.backgroundGradient()),
          Positioned(
            top: -100.h,
            right: -90.w,
            child: QuestionUI.glowingCircle(AppColors.yellow, 280.w)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .move(
                  begin: Offset.zero,
                  end: Offset(-15.w, 10.h),
                  duration: 5000.ms,
                ),
          ),
          Positioned(
            bottom: -140.h,
            left: -100.w,
            child: QuestionUI.glowingCircle(AppColors.sky, 320.w)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .move(
                  begin: Offset.zero,
                  end: Offset(20.w, -15.h),
                  duration: 6000.ms,
                ),
          ),
          SafeArea(
            child: MultiBlocListener(
              listeners: [
                BlocListener<QuestionCreateCubit, QuestionCreateState>(
                  listener: _onCreateState,
                ),
                BlocListener<QuestionUpdateCubit, QuestionUpdateState>(
                  listener: _onUpdateState,
                ),
              ],
              child: Column(
                children: [
                  SizedBox(height: 10.h),
                  _buildTopBar(isEdit),
                  SizedBox(height: 12.h),
                  Expanded(
                    child: isEdit
                        ? BlocConsumer<
                            QuestionDetailCubit,
                            QuestionDetailState
                          >(
                            listener: (context, state) {
                              if (state is QuestionDetailLoaded) {
                                _prefillFromEdit(state.question);
                                setState(() {});
                              }
                            },
                            builder: (context, state) {
                              if (state is QuestionDetailLoaded || _prefilled)
                                return _buildForm();
                              if (state is QuestionDetailFailure) {
                                return Center(
                                  child: Text(
                                    state.error,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                );
                              }
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.yellow,
                                ),
                              );
                            },
                          )
                        : Builder(
                            builder: (_) {
                              if (!_prefilled) {
                                _resetAnswersForType(_type);
                                _prefilled = true;
                              }
                              return _buildForm();
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onCreateState(BuildContext context, QuestionCreateState state) {
    if (state is QuestionCreateSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Question created successfully",
            style: GoogleFonts.poppins(fontSize: 13.sp),
          ),
          backgroundColor: Colors.greenAccent.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } else if (state is QuestionCreateFailure) {
      _showError(context, state.error, state.errors);
    }
  }

  void _onUpdateState(BuildContext context, QuestionUpdateState state) {
    if (state is QuestionUpdateSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            state.message,
            style: GoogleFonts.poppins(fontSize: 13.sp),
          ),
          backgroundColor: state.wasVersioned
              ? AppColors.orange
              : Colors.greenAccent.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } else if (state is QuestionUpdateFailure) {
      _showError(context, state.error, state.errors);
    }
  }

  void _showError(
    BuildContext context,
    String msg,
    Map<String, dynamic>? errors,
  ) {
    String formatFieldName(String key) {
      return key
          .replaceAll('title_question_en', 'English Title')
          .replaceAll('title_question_ar', 'Arabic Title')
          .replaceAll('text_question', 'Question Text')
          .replaceAll('answers', 'Answer')
          .replaceAll('_', ' ')
          .split(' ')
          .map((word) => word[0].toUpperCase() + word.substring(1))
          .join(' ');
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.dark,
        title: Text(
          "Validation Error",
          style: GoogleFonts.poppins(
            color: Colors.redAccent,
            fontWeight: FontWeight.w700,
            fontSize: 16.sp,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                msg,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 13.sp,
                ),
              ),
              if (errors != null && errors.isNotEmpty) ...[
                SizedBox(height: 12.h),
                ...errors.entries.map(
                  (e) => Padding(
                    padding: EdgeInsets.only(bottom: 6.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "• ",
                          style: GoogleFonts.poppins(
                            color: Colors.redAccent,
                            fontSize: 12.sp,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "${formatFieldName(e.key)}: ${(e.value is List ? (e.value as List).join(', ') : e.value.toString())}",
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12.sp,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "OK",
              style: GoogleFonts.poppins(
                color: AppColors.yellow,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(bool isEdit) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // توسيط المحتوى بالكامل
        mainAxisSize: MainAxisSize.min, // مهم جداً لضمان عدم تمدد الـ Row
        children: [
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              color: AppColors.yellow.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: AppColors.yellow.withOpacity(0.5)),
            ),
            child: Icon(
              Icons.quiz_outlined,
              color: AppColors.yellow,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 10.w),
          Flexible(
            // نستخدم Flexible بدلاً من Expanded للسماح بتصغير الخط إذا لزم الأمر
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                isEdit ? "Edit Question" : "New Question",
                style: GoogleFonts.cinzelDecorative(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: AppColors.sky.withOpacity(0.7),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: 16.w,
        ), // ✅ تقليل الـ Padding للموبايل
        children: [
          _buildTypeSelector(),
          SizedBox(height: 12.h),
          _buildTitleFields(),
          SizedBox(height: 12.h),
          _buildDifficultyAndScore(),
          SizedBox(height: 12.h),
          if (_type == QuestionType.fill) ...[
            _buildTextQuestionField(),
            SizedBox(height: 12.h),
          ],
          _buildMediaPickers(),
          SizedBox(height: 12.h),
          _buildAnswersSection(),
          SizedBox(height: 24.h),
          _buildSubmitButton(),
          SizedBox(height: 30.h),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return QuestionUI.glass(
      padding: EdgeInsets.all(12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Question Type",
            style: GoogleFonts.poppins(
              color: AppColors.yellow,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 10.h),
          // ✅ استخدام Wrap لضمان عدم تداخل الأزرار في الشاشات الصغيرة
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: QuestionType.values.map((t) {
              final selected = _type == t;
              final color = QuestionUI.typeColor(t.value);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _type = t;
                    _resetAnswersForType(t);
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? color.withOpacity(0.3)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: selected ? color : Colors.white.withOpacity(0.2),
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        QuestionUI.typeIcon(t.value),
                        color: selected ? color : Colors.white60,
                        size: 16.sp,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        t.value,
                        style: GoogleFonts.poppins(
                          color: selected ? Colors.white : Colors.white70,
                          fontSize: 11.sp,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleFields() {
    return QuestionUI.glass(
      padding: EdgeInsets.all(12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Title",
            style: GoogleFonts.poppins(
              color: AppColors.yellow,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 10.h),
          _field(_titleEn, "Title (English)"),
          SizedBox(height: 10.h),
          _field(_titleAr, "Title (Arabic)", isArabic: true),
        ],
      ),
    );
  }

  Widget _buildTextQuestionField() {
    return QuestionUI.glass(
      padding: EdgeInsets.all(12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Question Text",
            style: GoogleFonts.poppins(
              color: AppColors.yellow,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 10.h),
          TextFormField(
            controller: _textQuestion,
            maxLines: 4,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 13.sp),
            decoration: _inputDecoration("e.g. The capital of France is {1}."),
          ),
          SizedBox(height: 14.h),
          _buildLiveFillPreview(),
        ],
      ),
    );
  }

  Widget _buildLiveFillPreview() {
    final text = _textQuestion.text.trim();
    final hasBlanks = RegExp(r'\{\d+\}').hasMatch(text);
    final hasAnswers = _answers.any((a) => a.text.trim().isNotEmpty);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.orange.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.visibility_outlined,
                color: AppColors.orange,
                size: 14.sp,
              ),
              SizedBox(width: 5.w),
              Text(
                "Live Preview",
                style: GoogleFonts.poppins(
                  color: AppColors.orange,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          if (text.isEmpty)
            Text(
              "Start typing to see a preview...",
              style: GoogleFonts.poppins(
                color: Colors.white38,
                fontSize: 12.sp,
                fontStyle: FontStyle.italic,
              ),
            )
          else if (!hasBlanks)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13.sp,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.white38,
                      size: 12.sp,
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        "Tip: add {1}, {2}, ... to create blanks.",
                        style: GoogleFonts.poppins(
                          color: Colors.white38,
                          fontSize: 10.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            _renderFillRichPreview(text, hasAnswers),
        ],
      ),
    );
  }

  Widget _renderFillRichPreview(String text, bool hasAnswers) {
    final baseStyle = GoogleFonts.poppins(
      color: Colors.white,
      fontSize: 13.sp,
      height: 1.6,
    );
    final blankColor = AppColors.orange;
    final regex = RegExp(r'\{(\d+)\}');
    final spans = <InlineSpan>[];
    int lastEnd = 0;
    String? answerFor(int blankNumber) {
      for (final a in _answers) {
        if (a.text.trim().isEmpty) continue;
        final n = a.blankOrder > 0 ? a.blankOrder : 1;
        if (n == blankNumber) return a.text;
      }
      return null;
    }

    for (final m in regex.allMatches(text)) {
      if (m.start > lastEnd)
        spans.add(
          TextSpan(text: text.substring(lastEnd, m.start), style: baseStyle),
        );
      final n = int.tryParse(m.group(1) ?? '') ?? 0;
      if (n > 0) {
        final answer = hasAnswers ? answerFor(n) : null;
        final hasAns = answer != null && answer.isNotEmpty;
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 10.h),
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    constraints: BoxConstraints(minWidth: 60.w),
                    decoration: BoxDecoration(
                      color: hasAns
                          ? blankColor.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border(
                        bottom: BorderSide(color: blankColor, width: 1.6),
                      ),
                    ),
                    child: Text(
                      hasAns ? answer : '   ',
                      style: baseStyle.copyWith(
                        color: hasAns ? Colors.white : Colors.white54,
                        fontWeight: hasAns ? FontWeight.w600 : FontWeight.w400,
                        fontStyle: hasAns ? FontStyle.normal : FontStyle.italic,
                        fontSize: 12.sp,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Positioned(
                    top: -2,
                    left: -2,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 1.h,
                      ),
                      decoration: BoxDecoration(
                        color: blankColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: blankColor.withOpacity(0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        '$n',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      lastEnd = m.end;
    }
    if (lastEnd < text.length)
      spans.add(TextSpan(text: text.substring(lastEnd), style: baseStyle));
    return Text.rich(
      TextSpan(children: spans),
      textDirection: TextDirection.ltr,
    );
  }

  Widget _buildDifficultyAndScore() {
    return QuestionUI.glass(
      padding: EdgeInsets.all(12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Difficulty & Score",
                style: GoogleFonts.poppins(
                  color: AppColors.yellow,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: QuestionUI.difficultyColor(
                    _difficulty.value,
                  ).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(
                    color: QuestionUI.difficultyColor(
                      _difficulty.value,
                    ).withOpacity(0.5),
                  ),
                ),
                child: Text(
                  "${_difficulty.minScore}-${_difficulty.maxScore}",
                  style: GoogleFonts.poppins(
                    color: QuestionUI.difficultyColor(_difficulty.value),
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<QuestionDifficulty>(
                  value: _difficulty,
                  isExpanded: true,
                  dropdownColor: AppColors.dark,
                  decoration: InputDecoration(
                    labelText: "Difficulty",
                    labelStyle: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12.sp,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.06),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 14.h,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.15),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: QuestionUI.difficultyColor(_difficulty.value),
                        width: 1.5,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: Colors.redAccent),
                    ),
                  ),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  icon: Icon(
                    Icons.arrow_drop_down_circle,
                    color: QuestionUI.difficultyColor(_difficulty.value),
                    size: 24.sp,
                  ),
                  items: QuestionDifficulty.values
                      .map(
                        (d) => DropdownMenuItem(
                          value: d,
                          child: Row(
                            children: [
                              Container(
                                width: 8.w,
                                height: 8.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: QuestionUI.difficultyColor(d.value),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                d.value,
                                style: GoogleFonts.poppins(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _difficulty = v;
                      if (_score < v.minScore) _score = v.minScore;
                      if (_score > v.maxScore) _score = v.maxScore;
                      _scoreController.text = _score.toString();
                    });
                    _formKey.currentState?.validate();
                  },
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: TextFormField(
                  controller: _scoreController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    labelText: "Score",
                    labelStyle: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12.sp,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.06),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 14.h,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.15),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: AppColors.yellow,
                        width: 1.5,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: const BorderSide(color: Colors.redAccent),
                    ),
                  ),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null) return 'Score is required';
                    if (n < _difficulty.minScore || n > _difficulty.maxScore)
                      return '${_difficulty.displayName}: ${_difficulty.minScore}-${_difficulty.maxScore} only';
                    return null;
                  },
                  onChanged: (v) {
                    final n = int.tryParse(v);
                    if (n != null) _score = n;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPickers() {
    return QuestionUI.glass(
      padding: EdgeInsets.all(12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Media (optional - Choose One)",
            style: GoogleFonts.poppins(
              color: AppColors.yellow,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: _mediaTile(
                  icon: Icons.image_outlined,
                  label: "Image",
                  color: AppColors.sky,
                  onTap: _pickImage,
                  onRemove: _removeImage,
                  file: _imageFile,
                  fileName: _imageFileName,
                  existingUrl: _imageFile == null ? _existingImageUrl : null,
                  isImage: true,
                  isEnabled: _audioFile == null,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _mediaTile(
                  icon: Icons.audiotrack_outlined,
                  label: "Audio",
                  color: AppColors.orange,
                  onTap: _pickAudio,
                  onRemove: _removeAudio,
                  file: _audioFile,
                  fileName: _audioFileName,
                  existingUrl: _audioFile == null ? _existingAudioUrl : null,
                  isImage: false,
                  isEnabled: _imageFile == null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mediaTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required VoidCallback onRemove,
    File? file,
    String? fileName,
    String? existingUrl,
    required bool isImage,
    required bool isEnabled,
  }) {
    final hasFile = file != null;
    final hasExisting = !hasFile && existingUrl != null;
    final showsSomething = hasFile || hasExisting;
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: showsSomething
            ? color.withOpacity(0.2)
            : (isEnabled ? Colors.white.withOpacity(0.05) : Colors.black12),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: showsSomething
              ? color
              : (isEnabled
                    ? Colors.white.withOpacity(0.2)
                    : Colors.white.withOpacity(0.05)),
          width: showsSomething ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: isEnabled ? 1.0 : 0.4,
            child: GestureDetector(
              onTap: isEnabled ? onTap : null,
              child: Column(
                children: [
                  if (hasFile && isImage)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: Image.file(
                        file!,
                        height: 80.h,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  else if (hasExisting && isImage)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: Image.network(
                        existingUrl!,
                        height: 80.h,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.broken_image,
                          color: Colors.white60,
                          size: 32.sp,
                        ),
                      ),
                    )
                  else
                    Icon(
                      showsSomething ? Icons.check_circle : icon,
                      color: showsSomething ? color : Colors.white60,
                      size: 32.sp,
                    ),
                  SizedBox(height: 8.h),
                  Text(
                    hasFile
                        ? (fileName ?? "File selected")
                        : hasExisting
                        ? "Current $label"
                        : "Pick $label",
                    style: GoogleFonts.poppins(
                      color: showsSomething ? Colors.white : Colors.white60,
                      fontSize: 11.sp,
                      fontWeight: showsSomething
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          if (hasExisting && !isImage) ...[
            SizedBox(height: 8.h),
            AudioPreviewTile(url: existingUrl!, compact: true),
          ],
          if (showsSomething) ...[
            SizedBox(height: 10.h),
            GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close, color: Colors.redAccent, size: 14.sp),
                    SizedBox(width: 4.w),
                    Text(
                      "Remove",
                      style: GoogleFonts.poppins(
                        color: Colors.redAccent,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnswersSection() {
    return QuestionUI.glass(
      padding: EdgeInsets.all(12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Answers (${_answers.length})",
                style: GoogleFonts.poppins(
                  color: AppColors.yellow,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (_type != QuestionType.fill)
                GestureDetector(
                  onTap: () =>
                      setState(() => _answers.add(_AnswerDraft.forType(_type))),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.yellow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColors.yellow.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: AppColors.yellow, size: 14.sp),
                        SizedBox(width: 3.w),
                        Text(
                          "Add",
                          style: GoogleFonts.poppins(
                            color: AppColors.yellow,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 10.h),
          ..._answers.asMap().entries.map((e) {
            final idx = e.key;
            final a = e.value;
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: _buildAnswerRow(idx, a),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAnswerRow(int idx, _AnswerDraft a) {
    switch (_type) {
      case QuestionType.mcq:
        return _answerShell(
          idx,
          row: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() {
                  for (var i = 0; i < _answers.length; i++) {
                    _answers[i].isCorrect = (i == idx);
                  }
                }),
                child: Container(
                  width: 24.w,
                  height: 24.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: a.isCorrect
                        ? Colors.greenAccent.withOpacity(0.25)
                        : Colors.transparent,
                    border: Border.all(
                      color: a.isCorrect
                          ? Colors.greenAccent
                          : Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: a.isCorrect
                      ? Icon(
                          Icons.check,
                          color: Colors.greenAccent,
                          size: 16.sp,
                        )
                      : null,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: TextFormField(
                  initialValue: a.text,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13.sp,
                  ),
                  decoration: _inputDecoration("Answer ${idx + 1}"),
                  onChanged: (v) => a.text = v,
                ),
              ),
            ],
          ),
          onRemove: () => setState(() => _answers.removeAt(idx)),
        );
      case QuestionType.fill:
        return _answerShell(
          idx,
          row: Row(
            children: [
              Container(
                width: 32.w,
                padding: EdgeInsets.symmetric(vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.orange.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Center(
                  child: Text(
                    "#${idx + 1}",
                    style: GoogleFonts.poppins(
                      color: AppColors.orange,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: TextFormField(
                  initialValue: a.text,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13.sp,
                  ),
                  decoration: _inputDecoration("Blank answer"),
                  onChanged: (v) {
                    a.text = v;
                    a.blankOrder = idx + 1;
                  },
                ),
              ),
            ],
          ),
        );
      case QuestionType.arrange:
        return _answerShell(
          idx,
          row: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => a.isCorrect = !a.isCorrect),
                child: Container(
                  width: 24.w,
                  height: 24.w,
                  decoration: BoxDecoration(
                    color: a.isCorrect
                        ? Colors.greenAccent.withOpacity(0.25)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(
                      color: a.isCorrect
                          ? Colors.greenAccent
                          : Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: a.isCorrect
                      ? Icon(
                          Icons.check,
                          color: Colors.greenAccent,
                          size: 16.sp,
                        )
                      : null,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: TextFormField(
                  initialValue: a.text,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13.sp,
                  ),
                  decoration: _inputDecoration(
                    a.isCorrect ? "Word (in order)" : "Distractor",
                  ),
                  onChanged: (v) => a.text = v,
                ),
              ),
              if (a.isCorrect) ...[
                SizedBox(width: 6.w),
                SizedBox(
                  width: 50.w,
                  child: TextFormField(
                    key: ValueKey('arrange_order_$idx'),
                    initialValue: a.order > 0 ? a.order.toString() : '',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13.sp,
                    ),
                    decoration: _inputDecoration("N°"),
                    onChanged: (v) => a.order = int.tryParse(v) ?? 0,
                  ),
                ),
              ],
            ],
          ),
          onRemove: () => setState(() => _answers.removeAt(idx)),
        );
      case QuestionType.pair:
        return _answerShell(
          idx,
          row: Column(
            children: [
              TextFormField(
                initialValue: a.left,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 13.sp,
                ),
                decoration: _inputDecoration("Left (Arabic)"),
                textDirection: TextDirection.rtl,
                onChanged: (v) => a.left = v,
              ),
              SizedBox(height: 6.h),
              TextFormField(
                initialValue: a.right,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 13.sp,
                ),
                decoration: _inputDecoration("Right (English)"),
                onChanged: (v) => a.right = v,
              ),
            ],
          ),
          onRemove: () => setState(() => _answers.removeAt(idx)),
        );
    }
  }

  Widget _answerShell(int idx, {required Widget row, VoidCallback? onRemove}) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          row,
          if (onRemove != null) ...[
            SizedBox(height: 6.h),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: onRemove,
                child: Icon(
                  Icons.close,
                  color: Colors.redAccent.withOpacity(0.8),
                  size: 18.sp,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isEdit = widget.questionId != null;
    return BlocBuilder<QuestionCreateCubit, QuestionCreateState>(
      builder: (ctxC, cState) {
        return BlocBuilder<QuestionUpdateCubit, QuestionUpdateState>(
          builder: (ctxU, uState) {
            final loading =
                cState is QuestionCreateLoading ||
                uState is QuestionUpdateLoading;
            return SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: loading ? null : () => _submit(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.yellow,
                  foregroundColor: AppColors.dark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: loading
                    ? SizedBox(
                        width: 22.w,
                        height: 22.w,
                        child: const CircularProgressIndicator(
                          color: AppColors.dark,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        isEdit ? "Update Question" : "Create Question",
                        style: GoogleFonts.poppins(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            );
          },
        );
      },
    );
  }

  void _submit() async {
    if (!(_formKey.currentState?.validate() ?? true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please fix the Score field (${_difficulty.displayName}: ${_difficulty.minScore}-${_difficulty.maxScore}) before submitting.",
            style: GoogleFonts.poppins(fontSize: 13.sp),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final formData = FormData();
    formData.fields.add(MapEntry('type', _type.value));
    formData.fields.add(MapEntry('title_question_en', _titleEn.text.trim()));
    formData.fields.add(MapEntry('title_question_ar', _titleAr.text.trim()));
    formData.fields.add(MapEntry('difficulty', _difficulty.value));
    formData.fields.add(MapEntry('score', _score.toString()));
    if (_type == QuestionType.fill && _textQuestion.text.trim().isNotEmpty)
      formData.fields.add(MapEntry('text_question', _textQuestion.text.trim()));
    for (int i = 0; i < _answers.length; i++) {
      final a = _answers[i];
      if (_type == QuestionType.mcq) {
        formData.fields.add(
          MapEntry('answers[$i][text_answer]', a.text.trim()),
        );
        formData.fields.add(
          MapEntry('answers[$i][is_correct]', a.isCorrect ? '1' : '0'),
        );
      } else if (_type == QuestionType.fill) {
        formData.fields.add(
          MapEntry('answers[$i][text_answer]', a.text.trim()),
        );
        formData.fields.add(
          MapEntry(
            'answers[$i][blank_order]',
            (a.blankOrder > 0 ? a.blankOrder : (i + 1)).toString(),
          ),
        );
      } else if (_type == QuestionType.arrange) {
        formData.fields.add(
          MapEntry('answers[$i][text_answer]', a.text.trim()),
        );
        formData.fields.add(
          MapEntry('answers[$i][is_correct]', a.isCorrect ? '1' : '0'),
        );
        if (a.isCorrect)
          formData.fields.add(
            MapEntry(
              'answers[$i][order]',
              (a.order > 0 ? a.order : (i + 1)).toString(),
            ),
          );
      } else if (_type == QuestionType.pair) {
        formData.fields.add(MapEntry('answers[$i][left_text]', a.left.trim()));
        formData.fields.add(
          MapEntry('answers[$i][right_text]', a.right.trim()),
        );
      }
    }
    if (_imageFile != null)
      formData.files.add(
        MapEntry(
          'image',
          await awaitableFile(_imageFile!, _imageFileName ?? 'image.jpg'),
        ),
      );
    if (_audioFile != null)
      formData.files.add(
        MapEntry(
          'audio',
          await awaitableFile(_audioFile!, _audioFileName ?? 'audio.mp3'),
        ),
      );
    if (widget.questionId != null) {
      context.read<QuestionUpdateCubit>().updateQuestion(
        widget.questionId!,
        formData,
      );
    } else {
      context.read<QuestionCreateCubit>().createQuestion(formData);
    }
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
      _imageFileName = null;
      _existingImageUrl = null;
    });
  }

  void _removeAudio() {
    setState(() {
      _audioFile = null;
      _audioFileName = null;
      _existingAudioUrl = null;
    });
  }

  Widget _field(
    TextEditingController c,
    String label, {
    bool isArabic = false,
  }) {
    return TextFormField(
      controller: c,
      style: GoogleFonts.poppins(color: Colors.white, fontSize: 13.sp),
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      decoration: _inputDecoration(label),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(
        color: Colors.white.withOpacity(0.6),
        fontSize: 12.sp,
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: AppColors.yellow, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.single.path;
        final fileName = result.files.single.name;
        if (filePath != null) {
          setState(() {
            _imageFile = File(filePath);
            _imageFileName = fileName;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Image picking is not supported on Web in this mode',
              ),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  Future<void> _pickAudio() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.single.path;
        final fileName = result.files.single.name;
        if (filePath != null) {
          setState(() {
            _audioFile = File(filePath);
            _audioFileName = fileName;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick audio: $e')));
    }
  }
}

class _AnswerDraft {
  String text;
  bool isCorrect;
  int order;
  int blankOrder;
  String left;
  String right;
  _AnswerDraft({
    this.text = '',
    this.isCorrect = false,
    this.order = 0,
    this.blankOrder = 0,
    this.left = '',
    this.right = '',
  });
  factory _AnswerDraft.forType(QuestionType t) {
    switch (t) {
      case QuestionType.mcq:
      case QuestionType.arrange:
        return _AnswerDraft();
      case QuestionType.fill:
        return _AnswerDraft();
      case QuestionType.pair:
        return _AnswerDraft();
    }
  }
}

Future<MultipartFile> awaitableFile(File file, String filename) async {
  return await MultipartFile.fromFile(file.path, filename: filename);
}
