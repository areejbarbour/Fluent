import 'dart:io';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent/presentation/widgets/audio_preview_tile.dart';
import 'package:fluent/constants/app_colors.dart';
import 'package:fluent/utils/teacher_permissions.dart';
import 'package:fluent/constants/strings.dart';
import 'package:fluent/cubit/teacher/courses/delete/lesson_delete_cubit.dart';
import 'package:fluent/cubit/teacher/courses/delete/lesson_delete_state.dart';
import 'package:fluent/cubit/teacher/courses/form/lesson_form_cubit.dart';
import 'package:fluent/cubit/teacher/courses/form/lesson_form_state.dart';
import 'package:fluent/cubit/teacher/tests/delete/test_delete_cubit.dart';
import 'package:fluent/cubit/teacher/tests/delete/test_delete_state.dart';
import 'package:fluent/data/models/lesson_model.dart';
import 'package:fluent/data/models/test_model.dart';
import 'package:fluent/cubit/teacher/words/create/word_create_cubit.dart';
import 'package:fluent/cubit/teacher/words/create/word_create_state.dart';
import 'package:fluent/cubit/teacher/words/update/word_update_cubit.dart';
import 'package:fluent/cubit/teacher/words/update/word_update_state.dart';
import 'package:fluent/cubit/teacher/words/delete/word_delete_cubit.dart';
import 'package:fluent/cubit/teacher/words/delete/word_delete_state.dart';
import 'package:fluent/data/models/word_model.dart';
import 'package:fluent/data/repository/lesson_repository.dart';
import 'package:fluent/data/repository/test_repository.dart';
import 'package:fluent/helper/lessons/lesson_helpers.dart';
import 'package:fluent/helper/questions/question_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

final RegExp enRegex = RegExp(r'^[a-zA-Z0-9\s\-_]+$');
final RegExp arRegex = RegExp(r'^[\u0600-\u06FF\s0-9\-_]+$');

class LessonFormScreen extends StatefulWidget {
  final int? courseId;
  final LessonModel? lesson;
  final String? courseStatus;

  const LessonFormScreen({
    super.key,
    this.courseId,
    this.lesson,
    this.courseStatus,
  });

  @override
  State<LessonFormScreen> createState() => _LessonFormScreenState();
}

class _LessonFormScreenState extends State<LessonFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleEnCtrl,
      _titleArCtrl,
      _orderCtrl,
      _xpCtrl;
  PlatformFile? _selectedVideo;

  List<TestModel> _lessonTests = [];
  bool _isLoadingTest = false;

  List<WordModel> _lessonWords = [];

  String? _currentVideoUrl;
  int _commentsCount = 0;
  bool _isLoadingDetails = false;

  bool get isEditMode => widget.lesson != null;

  /// حالة الدرس الفعلية (مش الكورس)
  String get _lessonStatus => (widget.lesson?.status ?? '').toLowerCase();

  /// إنشاء درس جديد: فقط إذا الكورس pending
  bool get canCreateLesson {
    if (isEditMode) return true;
    return (widget.courseStatus ?? '').toLowerCase() == 'pending';
  }

  /// Backend TeacherLessonService: blocked CLOSED|ARCHIVED|APPROVED|IN_REVIEW
  bool get isRestrictedEdit {
    if (!isEditMode) return !canCreateLesson;
    return !TeacherPermissions.canEditLesson(_lessonStatus);
  }

  /// Backend: published allows only title_en, title_ar, xp_points
  bool get isPublishedEdit =>
      isEditMode && TeacherPermissions.isPublishedLessonEdit(_lessonStatus);

  /// Backend: delete only draft|pending|changes_requested
  bool get canDelete {
    if (!isEditMode) return false;
    return TeacherPermissions.canDeleteLesson(_lessonStatus);
  }

  /// Backend TeacherWordService: draft|pending|changes_requested only
  bool get canManageWords {
    if (!isEditMode) return false;
    return TeacherPermissions.canManageWords(_lessonStatus);
  }

  @override
  void initState() {
    super.initState();
    _titleEnCtrl = TextEditingController(text: widget.lesson?.titleEn ?? '');
    _titleArCtrl = TextEditingController(text: widget.lesson?.titleAr ?? '');
    _orderCtrl = TextEditingController(
      text: widget.lesson?.order.toString() ?? '1',
    );
    _xpCtrl = TextEditingController(
      text: widget.lesson?.xpPoints.toString() ?? '20',
    );

    if (isEditMode && widget.lesson != null) {
      _fetchLessonDetails();
      _fetchLessonTests();
    }
  }

  Future<void> _fetchLessonDetails() async {
    if (widget.lesson == null) return;

    setState(() => _isLoadingDetails = true);
    try {
      final lessonRepo = context.read<LessonRepository>();
      final result = await lessonRepo.getLessonDetails(widget.lesson!.id);

      if (!mounted) return;

      if (result['success'] == true) {
        final lessonJson = result['lesson'];
        final comments = result['comments'];

        String? video;
        if (lessonJson is Map) {
          final v = lessonJson['video']?.toString();
          if (v != null && v.trim().isNotEmpty) video = v;

          final en = lessonJson['title_en']?.toString();
          final ar = lessonJson['title_ar']?.toString();
          final order = lessonJson['order'];
          final xp = lessonJson['xp_points'];

          if (en != null && en.isNotEmpty) _titleEnCtrl.text = en;
          if (ar != null && ar.isNotEmpty) _titleArCtrl.text = ar;
          if (order != null) _orderCtrl.text = order.toString();
          if (xp != null) _xpCtrl.text = xp.toString();
        }

        // Backend puts words at response root, not inside lesson.
        List<WordModel> words = WordModel.listFrom(result['words']);
        if (words.isEmpty && lessonJson is Map) {
          words = WordModel.listFrom(lessonJson['words']);
        }

        setState(() {
          _currentVideoUrl = video;
          _commentsCount = comments is List ? comments.length : 0;
          _lessonWords = words;
          _isLoadingDetails = false;
        });
      } else {
        setState(() => _isLoadingDetails = false);
      }
    } catch (e) {
      print('_fetchLessonDetails error: $e');
      if (mounted) setState(() => _isLoadingDetails = false);
    }
  }

  Future<void> _fetchLessonTests() async {
    if (widget.lesson == null) {
      setState(() {
        _lessonTests = [];
        _isLoadingTest = false;
      });
      return;
    }

    setState(() => _isLoadingTest = true);
    try {
      final testRepo = context.read<TestRepository>();
      final result = await testRepo.getAllTests();

      if (!mounted) return;

      if (result['success'] == true) {
        final all = result['data'] as List<TestModel>;
        final matches = all
            .where(
              (t) =>
                  t.testableType.toLowerCase() == 'lesson' &&
                  t.testableId == widget.lesson!.id,
            )
            .toList();
        setState(() {
          _lessonTests = matches;
          _isLoadingTest = false;
        });
      } else {
        setState(() {
          _lessonTests = [];
          _isLoadingTest = false;
        });
      }
    } catch (e, stack) {
      print('_fetchLessonTests error: $e');
      print('stack: $stack');
      if (mounted) {
        setState(() {
          _lessonTests = [];
          _isLoadingTest = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleEnCtrl.dispose();
    _titleArCtrl.dispose();
    _orderCtrl.dispose();
    _xpCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.size > 150 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video size must not exceed 150MB'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      setState(() => _selectedVideo = file);
    }
  }

  void _submit(BuildContext context) async {
    if (isRestrictedEdit && !isPublishedEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This lesson cannot be modified in its current status'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    if (!isEditMode && _selectedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a video file'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final orderValue = int.tryParse(_orderCtrl.text) ?? 1;
    final xpValue = int.tryParse(_xpCtrl.text) ?? 20;

    final formData = FormData.fromMap({
      'title_en': _titleEnCtrl.text.trim(),
      'title_ar': _titleArCtrl.text.trim(),
      'order': orderValue,
      'xp_points': xpValue,
    });

    if (_selectedVideo != null && _selectedVideo!.path != null) {
      formData.files.add(
        MapEntry(
          'video',
          await MultipartFile.fromFile(
            _selectedVideo!.path!,
            filename: _selectedVideo!.name,
          ),
        ),
      );
    }

    if (isEditMode) {
      context.read<LessonFormCubit>().updateLesson(widget.lesson!.id, formData);
    } else {
      context.read<LessonFormCubit>().createLesson(widget.courseId!, formData);
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.dark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
        ),
        title: Text(
          'Delete Lesson?',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'This will permanently delete the lesson with all its tests and details. This cannot be undone.',
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.8),
            fontSize: 13.sp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<LessonDeleteCubit>().deleteLesson(widget.lesson!.id);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                color: Colors.redAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 📁 lib/presentation/screens/teacher/lessons/lesson_form_screen.dart

  // ❌ احذف الدالة القديمة واستبدلها بهذه:

  Future<void> _openEditTest(TestModel test) async {
    // ✅ 1. عرض مؤشر تحميل
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.yellow),
      ),
    );

    try {
      // ✅ 2. جلب الاختبار الكامل مع الأسئلة من الباك إند
      final repo = context.read<TestRepository>();
      final result = await repo.getTestById(test.id);

      // ✅ 3. إغلاق مؤشر التحميل
      if (mounted) Navigator.pop(context);

      if (!mounted) return;

      if (result['success'] == true && result['data'] is TestModel) {
        final fullTest = result['data'] as TestModel;

        // ✅ 4. فتح شاشة التعديل مع الاختبار الكامل
        final editResult = await Navigator.pushNamed(
          context,
          testFormRoute,
          arguments: {
            'testableType': 'lesson',
            'testableId': widget.lesson!.id,
            'title': widget.lesson!.titleEn.isNotEmpty
                ? widget.lesson!.titleEn
                : widget.lesson!.titleAr,
            'initialTest': fullTest, // ✅ الآن يحتوي على الأسئلة
          },
        );

        // ✅ 5. تحديث قائمة الاختبارات بعد العودة
        if (editResult == true && mounted) {
          _fetchLessonTests();
        }
      } else {
        // ❌ عرض رسالة خطأ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to load test details'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // ✅ إغلاق مؤشر التحميل في حالة الخطأ
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _openCreateTest() {
    Navigator.pushNamed(
      context,
      testFormRoute,
      arguments: {
        'testableType': 'lesson',
        'testableId': widget.lesson!.id,
        'title': widget.lesson!.titleEn.isNotEmpty
            ? widget.lesson!.titleEn
            : widget.lesson!.titleAr,
      },
    ).then((_) {
      if (mounted) _fetchLessonTests();
    });
  }

  void _confirmDeleteTest(TestModel test) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.dark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
        ),
        title: Text(
          'Delete Test?',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Delete "${test.titleEn.isNotEmpty ? test.titleEn : test.titleAr}"?\nThis cannot be undone.',
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.8),
            fontSize: 13.sp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<TestDeleteCubit>().deleteTest(test.id);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                color: Colors.redAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<LessonFormCubit, LessonFormState>(
          listener: (context, state) {
            if (state is LessonFormSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isEditMode
                        ? 'Lesson updated successfully'
                        : 'Lesson created successfully',
                  ),
                  backgroundColor: Colors.greenAccent,
                ),
              );
              Navigator.pop(context, true);
            }
            if (state is LessonFormFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          },
        ),
        BlocListener<LessonDeleteCubit, LessonDeleteState>(
          listener: (context, state) {
            if (state is LessonDeleteSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.greenAccent,
                ),
              );
              Navigator.pop(context, true);
            }
            if (state is LessonDeleteFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          },
        ),
        BlocListener<TestDeleteCubit, TestDeleteState>(
          listener: (context, state) {
            if (state is TestDeleteSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.greenAccent,
                ),
              );
              _fetchLessonTests();
            }
            if (state is TestDeleteFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          },
        ),
        BlocListener<WordCreateCubit, WordCreateState>(
          listener: (context, state) {
            if (state is WordCreateSuccess) {
              setState(() {
                final list = List<WordModel>.from(_lessonWords);
                if (!list.any((w) => w.id == state.word.id)) {
                  list.add(state.word);
                }
                _lessonWords = list;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.greenAccent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else if (state is WordCreateFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
        BlocListener<WordUpdateCubit, WordUpdateState>(
          listener: (context, state) {
            if (state is WordUpdateSuccess) {
              setState(() {
                final list = List<WordModel>.from(_lessonWords);
                final i = list.indexWhere((w) => w.id == state.word.id);
                if (i >= 0) {
                  list[i] = state.word;
                } else {
                  list.add(state.word);
                }
                _lessonWords = list;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.greenAccent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else if (state is WordUpdateFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
        BlocListener<WordDeleteCubit, WordDeleteState>(
          listener: (context, state) {
            if (state is WordDeleteSuccess) {
              setState(() {
                _lessonWords = _lessonWords
                    .where((w) => w.id != state.wordId)
                    .toList();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.greenAccent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else if (state is WordDeleteFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
      ],
      child: _FormView(
        formKey: _formKey,
        titleEnCtrl: _titleEnCtrl,
        titleArCtrl: _titleArCtrl,
        orderCtrl: _orderCtrl,
        xpCtrl: _xpCtrl,
        selectedVideo: _selectedVideo,
        currentVideoUrl: _currentVideoUrl,
        commentsCount: _commentsCount,
        isLoadingDetails: _isLoadingDetails,
        isEditMode: isEditMode,
        isRestrictedEdit: isRestrictedEdit,
        isPublishedEdit: isPublishedEdit,
        canDelete: canDelete,
        canManageWords: canManageWords,
        lesson: widget.lesson,
        lessonTests: _lessonTests,
        lessonWords: _lessonWords,
        isLoadingTest: _isLoadingTest,
        onPickVideo: _pickVideo,
        onSubmit: () => _submit(context),
        onDelete: () => _confirmDelete(context),
        onEditTest: _openEditTest,
        onCreateTest: _openCreateTest,
        onDeleteTest: _confirmDeleteTest,
        onAddWord: () => _openWordForm(context),
        onEditWord: (w) => _openWordForm(context, word: w),
        onDeleteWord: (w) => _confirmDeleteWord(context, w),
      ),
    );
  }

  void _openWordForm(BuildContext context, {WordModel? word}) {
    if (!canManageWords || widget.lesson == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Words can only be managed when the lesson is draft, pending, or changes requested.',
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WordFormSheet(
        lessonId: widget.lesson!.id,
        word: word,
        onSubmit:
            ({
              required String en,
              required String ar,
              File? audioFile,
              String? audioFileName,
            }) {
              if (word != null) {
                context.read<WordUpdateCubit>().updateWord(
                  wordId: word.id,
                  wordEn: en,
                  wordAr: ar,
                  audioFile: audioFile,
                  audioFileName: audioFileName,
                );
              } else {
                if (audioFile == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Audio file is required to create a word.'),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                context.read<WordCreateCubit>().createWord(
                  lessonId: widget.lesson!.id,
                  wordEn: en,
                  wordAr: ar,
                  audioFile: audioFile,
                  audioFileName: audioFileName,
                );
              }
            },
      ),
    );
  }

  void _confirmDeleteWord(BuildContext context, WordModel word) {
    if (!canManageWords) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.dark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'Delete Word',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Delete "${word.wordEn}" / "${word.wordAr}"?',
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<WordDeleteCubit>().deleteWord(word.id);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                color: Colors.redAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// Form View
// ═══════════════════════════════════════════════

class _FormView extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleEnCtrl, titleArCtrl, orderCtrl, xpCtrl;
  final PlatformFile? selectedVideo;
  final String? currentVideoUrl;
  final int commentsCount;
  final bool isLoadingDetails;
  final bool isEditMode;
  final bool isRestrictedEdit;
  final bool isPublishedEdit;
  final bool canDelete;
  final bool canManageWords;
  final LessonModel? lesson;
  final List<TestModel> lessonTests;
  final List<WordModel> lessonWords;
  final bool isLoadingTest;
  final VoidCallback onPickVideo, onSubmit, onDelete;
  final void Function(TestModel test)? onEditTest;
  final VoidCallback? onCreateTest;
  final void Function(TestModel test)? onDeleteTest;
  final VoidCallback? onAddWord;
  final void Function(WordModel word)? onEditWord;
  final void Function(WordModel word)? onDeleteWord;

  const _FormView({
    required this.formKey,
    required this.titleEnCtrl,
    required this.titleArCtrl,
    required this.orderCtrl,
    required this.xpCtrl,
    required this.selectedVideo,
    this.currentVideoUrl,
    this.commentsCount = 0,
    this.isLoadingDetails = false,
    required this.isEditMode,
    required this.isRestrictedEdit,
    required this.isPublishedEdit,
    required this.canDelete,
    required this.canManageWords,
    required this.lesson,
    required this.lessonTests,
    this.lessonWords = const [],
    required this.isLoadingTest,
    required this.onPickVideo,
    required this.onSubmit,
    required this.onDelete,
    this.onEditTest,
    this.onCreateTest,
    this.onDeleteTest,
    this.onAddWord,
    this.onEditWord,
    this.onDeleteWord,
  });

  @override
  Widget build(BuildContext context) {
    final fieldsEnabled = !isRestrictedEdit || isPublishedEdit;

    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 10.h),
                _buildTopBar(context),
                SizedBox(height: 12.h),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isRestrictedEdit && !isPublishedEdit) ...[
                            _buildRestrictedBanner(),
                            SizedBox(height: 12.h),
                          ],
                          _buildTextField(
                            titleEnCtrl,
                            'Title (English)',
                            Icons.translate,
                            isArabic: false,
                            isEnabled: fieldsEnabled,
                          ),
                          SizedBox(height: 10.h),
                          _buildTextField(
                            titleArCtrl,
                            'Title (Arabic)',
                            Icons.translate,
                            isArabic: true,
                            isEnabled: fieldsEnabled,
                          ),
                          SizedBox(height: 10.h),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  orderCtrl,
                                  'Order',
                                  Icons.format_list_numbered,
                                  isNum: true,
                                  isEnabled: fieldsEnabled && !isPublishedEdit,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: _buildTextField(
                                  xpCtrl,
                                  'XP Points',
                                  Icons.star_rounded,
                                  isNum: true,
                                  isEnabled: fieldsEnabled,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          _buildVideoPicker(
                            context,
                            isEnabled: fieldsEnabled && !isPublishedEdit,
                          ),
                          if (isEditMode && commentsCount > 0) ...[
                            SizedBox(height: 10.h),
                            QuestionUI.glass(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 10.h,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.comment_outlined,
                                    color: AppColors.sky,
                                    size: 18.sp,
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    '$commentsCount comment${commentsCount == 1 ? '' : 's'}',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white70,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          if (isEditMode) ...[
                            SizedBox(height: 20.h),
                            _buildWordsSection(context),
                            SizedBox(height: 20.h),
                            _buildTestSection(context),
                          ],

                          if (fieldsEnabled) ...[
                            SizedBox(height: 24.h),
                            _buildSubmitButton(context),
                          ],
                          if (isEditMode && canDelete) ...[
                            SizedBox(height: 16.h),
                            _buildDeleteButton(context),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestrictedBanner() {
    return QuestionUI.glass(
      padding: EdgeInsets.all(12.w),
      borderColor: Colors.redAccent.withOpacity(0.4),
      child: Row(
        children: [
          Icon(Icons.lock_outline, color: Colors.redAccent, size: 18.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'This lesson is in a restricted status and cannot be modified.',
              style: GoogleFonts.poppins(
                color: Colors.redAccent,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordsSection(BuildContext context) {
    return QuestionUI.glass(
      padding: EdgeInsets.all(14.w),
      borderColor: AppColors.orange.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.translate_rounded,
                color: AppColors.orange,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Words (${lessonWords.length})',
                  style: GoogleFonts.poppins(
                    color: AppColors.orange,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (canManageWords && onAddWord != null)
                GestureDetector(
                  onTap: onAddWord,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColors.orange.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, color: AppColors.orange, size: 14.sp),
                        SizedBox(width: 4.w),
                        Text(
                          'Add',
                          style: GoogleFonts.poppins(
                            color: AppColors.orange,
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
          if (!canManageWords) ...[
            SizedBox(height: 8.h),
            Text(
              'Words can only be managed when the lesson is draft, pending, or changes requested.',
              style: GoogleFonts.poppins(
                color: Colors.white38,
                fontSize: 10.sp,
              ),
            ),
          ],
          SizedBox(height: 12.h),
          if (lessonWords.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Text(
                'No words yet',
                style: GoogleFonts.poppins(
                  color: Colors.white54,
                  fontSize: 12.sp,
                ),
              ),
            )
          else
            ...lessonWords.map((w) {
              return Container(
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32.w,
                      height: 32.w,
                      decoration: BoxDecoration(
                        color: AppColors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.abc,
                        color: AppColors.orange,
                        size: 16.sp,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            w.wordEn,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            w.wordAr,
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 12.sp,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ),
                    ),
                    if (w.hasAudio) ...[
                      AudioPreviewTile(url: w.audio!, compact: true),
                      SizedBox(width: 6.w),
                    ],
                    if (canManageWords) ...[
                      GestureDetector(
                        onTap: onEditWord == null ? null : () => onEditWord!(w),
                        child: Padding(
                          padding: EdgeInsets.all(6.w),
                          child: Icon(
                            Icons.edit_outlined,
                            color: AppColors.sky,
                            size: 18.sp,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: onDeleteWord == null
                            ? null
                            : () => onDeleteWord!(w),
                        child: Padding(
                          padding: EdgeInsets.all(6.w),
                          child: Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                            size: 18.sp,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildTestSection(BuildContext context) {
    return QuestionUI.glass(
      padding: EdgeInsets.all(14.w),
      borderColor: AppColors.sky.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.quiz_outlined, color: AppColors.sky, size: 20.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Lesson Tests (${lessonTests.length})',
                  style: GoogleFonts.poppins(
                    color: AppColors.sky,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (isLoadingTest)
            Center(
              child: Padding(
                padding: EdgeInsets.all(20.h),
                child: const CircularProgressIndicator(color: AppColors.yellow),
              ),
            )
          else if (lessonTests.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Text(
                'No tests yet for this lesson',
                style: GoogleFonts.poppins(
                  color: Colors.white54,
                  fontSize: 12.sp,
                ),
              ),
            )
          else
            ...lessonTests.map((test) {
              // ✅ حالة الاختبار فقط
              final canEdit = test.canEdit;
              final canDel = test.canDelete;

              return Container(
                margin: EdgeInsets.only(bottom: 10.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.sky.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      test.titleEn.isNotEmpty ? test.titleEn : test.titleAr,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 4.h,
                      children: [
                        _testChip(
                          icon: Icons.check_circle_outline,
                          label: 'Pass: ${test.passingScore}%',
                          color: AppColors.yellow,
                        ),
                        _testChip(
                          icon: Icons.info_outline,
                          label: test.status.toUpperCase(),
                          color: StatusUI.statusColor(test.status),
                        ),
                      ],
                    ),
                    if (canEdit || canDel) ...[
                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          if (canEdit && onEditTest != null)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => onEditTest!(test),
                                icon: Icon(Icons.edit, size: 14.sp),
                                label: Text(
                                  'Edit',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.sky.withOpacity(
                                    0.2,
                                  ),
                                  foregroundColor: AppColors.sky,
                                  padding: EdgeInsets.symmetric(vertical: 8.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                ),
                              ),
                            ),
                          if (canEdit && canDel) SizedBox(width: 8.w),
                          if (canDel && onDeleteTest != null)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => onDeleteTest!(test),
                                icon: Icon(Icons.delete_outline, size: 14.sp),
                                label: Text(
                                  'Delete',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent.withOpacity(
                                    0.2,
                                  ),
                                  foregroundColor: Colors.redAccent,
                                  padding: EdgeInsets.symmetric(vertical: 8.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }),
          // Add Test: مسموح طالما الدرس مش restricted بالكامل
          if (!isRestrictedEdit || isPublishedEdit) ...[
            SizedBox(height: 8.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onCreateTest,
                icon: Icon(Icons.add, size: 18.sp),
                label: Text(
                  'Add Test',
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sky.withOpacity(0.2),
                  foregroundColor: AppColors.sky,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _testChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12.sp),
          SizedBox(width: 4.w),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() => Stack(
    children: [
      Container(decoration: QuestionUI.backgroundGradient()),
      Positioned(
        top: -120.h,
        right: -100.w,
        child: QuestionUI.glowingCircle(AppColors.yellow, 320.w)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .move(
              begin: Offset.zero,
              end: const Offset(-15, 10),
              duration: 5000.ms,
            ),
      ),
      Positioned(
        bottom: -160.h,
        left: -110.w,
        child: QuestionUI.glowingCircle(AppColors.sky, 380.w)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .move(
              begin: Offset.zero,
              end: const Offset(20, -15),
              duration: 6000.ms,
            ),
      ),
    ],
  );

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
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
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              color: AppColors.yellow.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: AppColors.yellow.withOpacity(0.5)),
            ),
            child: const Icon(
              Icons.play_lesson_rounded,
              color: AppColors.yellow,
              size: 20,
            ),
          ),
          SizedBox(width: 10.w),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                isEditMode ? 'Edit Lesson' : 'New Lesson',
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

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool isArabic = false,
    bool isNum = false,
    bool isEnabled = true,
  }) {
    return QuestionUI.glass(
      radius: 12,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: TextFormField(
        controller: ctrl,
        enabled: isEnabled,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        inputFormatters: isNum
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        style: GoogleFonts.poppins(
          color: isEnabled ? Colors.white : Colors.white54,
          fontSize: 13.sp,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            color: Colors.white54,
            fontSize: 12.sp,
          ),
          prefixIcon: Icon(icon, color: AppColors.yellow, size: 18.sp),
          border: InputBorder.none,
        ),
        validator: (v) {
          if (!isEnabled) return null;
          if (v == null || v.trim().isEmpty) return 'Required';
          final t = v.trim();
          if (t.length > 255) return 'Max 255 characters';
          if (label.contains('English') && !enRegex.hasMatch(t)) {
            return 'English: letters, numbers, spaces, - and _ only';
          }
          if (label.contains('Arabic') && !arRegex.hasMatch(t)) {
            return 'Arabic: letters, numbers, spaces, - and _ only';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildVideoPicker(BuildContext context, {bool isEnabled = true}) {
    final hasExistingVideo =
        currentVideoUrl != null && currentVideoUrl!.isNotEmpty;
    final hasNewVideo = selectedVideo != null;

    return QuestionUI.glass(
      radius: 14,
      borderColor: isEnabled
          ? AppColors.sky.withOpacity(0.4)
          : Colors.white.withOpacity(0.1),
      child: GestureDetector(
        onTap: isEnabled ? onPickVideo : null,
        child: Container(
          padding: EdgeInsets.all(14.w),
          child: Column(
            children: [
              if (isLoadingDetails)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: SizedBox(
                    width: 22.w,
                    height: 22.w,
                    child: const CircularProgressIndicator(
                      color: AppColors.sky,
                      strokeWidth: 2,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.video_library_rounded,
                  color: isEnabled ? AppColors.sky : Colors.white54,
                  size: 28.sp,
                ),
              SizedBox(height: 6.h),
              Text(
                hasNewVideo
                    ? selectedVideo!.name
                    : hasExistingVideo
                    ? 'Current video attached'
                    : (isEnabled
                          ? 'Tap to select video file'
                          : 'Video cannot be changed'),
                style: GoogleFonts.poppins(
                  color: isEnabled ? Colors.white : Colors.white54,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              if (hasNewVideo) ...[
                SizedBox(height: 4.h),
                Text(
                  '${(selectedVideo!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 10.sp,
                  ),
                ),
              ] else if (hasExistingVideo) ...[
                SizedBox(height: 4.h),
                Text(
                  currentVideoUrl!,
                  style: GoogleFonts.poppins(
                    color: Colors.white38,
                    fontSize: 9.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return BlocBuilder<LessonFormCubit, LessonFormState>(
      builder: (context, state) {
        final isLoading = state is LessonFormLoading;
        return GestureDetector(
          onTap: isLoading ? null : onSubmit,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 14.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.yellow, AppColors.orange],
              ),
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.yellow.withOpacity(0.4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 22.w,
                      height: 22.w,
                      child: const CircularProgressIndicator(
                        color: AppColors.dark,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      isEditMode ? 'Update Lesson' : 'Create Lesson',
                      style: GoogleFonts.poppins(
                        color: AppColors.dark,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return BlocBuilder<LessonDeleteCubit, LessonDeleteState>(
      builder: (context, state) {
        final isDeleting = state is LessonDeleteLoading;
        return GestureDetector(
          onTap: isDeleting ? null : onDelete,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 14.h),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
            ),
            child: Center(
              child: isDeleting
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(
                        color: Colors.redAccent,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Delete Lesson',
                          style: GoogleFonts.poppins(
                            color: Colors.redAccent,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _WordFormSheet extends StatefulWidget {
  final int lessonId;
  final WordModel? word;

  /// [audioFile] is required on create; optional on update.
  final void Function({
    required String en,
    required String ar,
    File? audioFile,
    String? audioFileName,
  })
  onSubmit;

  const _WordFormSheet({
    required this.lessonId,
    this.word,
    required this.onSubmit,
  });

  @override
  State<_WordFormSheet> createState() => _WordFormSheetState();
}

class _WordFormSheetState extends State<_WordFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _enCtrl;
  late final TextEditingController _arCtrl;

  /// Matches backend StoreWordRequest / UpdateWordRequest regex.
  static final _enRegex = RegExp(r'^[a-zA-Z0-9\s\-_]+$');
  static final _arRegex = RegExp(r'^[\u0600-\u06FF\s0-9\-_]+$', unicode: true);

  /// Backend max:5120 (KB) => 5 MB
  static const int _maxAudioBytes = 5 * 1024 * 1024;

  PlatformFile? _pickedAudio;
  bool get _isEdit => widget.word != null;

  @override
  void initState() {
    super.initState();
    _enCtrl = TextEditingController(text: widget.word?.wordEn ?? '');
    _arCtrl = TextEditingController(text: widget.word?.wordAr ?? '');
  }

  @override
  void dispose() {
    _enCtrl.dispose();
    _arCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'wav', 'ogg', 'm4a'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final size = file.size;
    if (size > _maxAudioBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audio must be 5MB or smaller.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (file.path == null || file.path!.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not read the selected audio file.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _pickedAudio = file);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (!_isEdit && _pickedAudio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audio file is required.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    File? audioFile;
    String? audioName;
    if (_pickedAudio != null && _pickedAudio!.path != null) {
      audioFile = File(_pickedAudio!.path!);
      audioName = _pickedAudio!.name;
    }

    widget.onSubmit(
      en: _enCtrl.text.trim(),
      ar: _arCtrl.text.trim(),
      audioFile: audioFile,
      audioFileName: audioName,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  _isEdit ? 'Edit Word' : 'Add Word',
                  style: GoogleFonts.cinzelDecorative(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  _isEdit
                      ? 'Update the word texts. Audio is optional.'
                      : 'English + Arabic + audio are required.',
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 11.sp,
                  ),
                ),
                SizedBox(height: 16.h),
                QuestionUI.glass(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: TextFormField(
                    controller: _enCtrl,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13.sp,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Word (English)',
                      labelStyle: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: 12.sp,
                      ),
                      border: InputBorder.none,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (!_enRegex.hasMatch(v.trim())) {
                        return 'Only English letters, numbers, spaces, - and _';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 12.h),
                QuestionUI.glass(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: TextFormField(
                    controller: _arCtrl,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13.sp,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Word (Arabic)',
                      labelStyle: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: 12.sp,
                      ),
                      border: InputBorder.none,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (!_arRegex.hasMatch(v.trim())) {
                        return 'Only Arabic letters, numbers, spaces, - and _';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 16.h),
                // Existing audio preview (edit mode)
                if (_isEdit &&
                    widget.word != null &&
                    widget.word!.hasAudio &&
                    _pickedAudio == null) ...[
                  QuestionUI.glass(
                    padding: EdgeInsets.all(12.w),
                    child: AudioPreviewTile(
                      url: widget.word!.audio!,
                      label: 'Current audio',
                    ),
                  ),
                  SizedBox(height: 10.h),
                ],
                // Picker
                GestureDetector(
                  onTap: _pickAudio,
                  child: QuestionUI.glass(
                    padding: EdgeInsets.all(14.w),
                    borderColor: AppColors.orange.withOpacity(0.45),
                    child: Row(
                      children: [
                        Icon(
                          Icons.audiotrack_rounded,
                          color: AppColors.orange,
                          size: 22.sp,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _pickedAudio != null
                                    ? _pickedAudio!.name
                                    : (_isEdit
                                          ? 'Replace audio (optional)'
                                          : 'Select audio (required)'),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                _pickedAudio != null
                                    ? '${((_pickedAudio!.size) / 1024).toStringAsFixed(0)} KB · mp3/wav/ogg/m4a · max 5MB'
                                    : 'mp3, wav, ogg, m4a · max 5MB',
                                style: GoogleFonts.poppins(
                                  color: Colors.white54,
                                  fontSize: 10.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_pickedAudio != null)
                          GestureDetector(
                            onTap: () => setState(() => _pickedAudio = null),
                            child: Icon(
                              Icons.close,
                              color: Colors.redAccent,
                              size: 18.sp,
                            ),
                          )
                        else
                          Icon(
                            Icons.upload_file_rounded,
                            color: AppColors.orange,
                            size: 20.sp,
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      _isEdit ? 'Update Word' : 'Create Word',
                      style: GoogleFonts.poppins(
                        color: AppColors.dark,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
