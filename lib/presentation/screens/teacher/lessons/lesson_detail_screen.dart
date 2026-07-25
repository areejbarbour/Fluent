import 'package:fluent/cubit/teacher/lessons/lesson_detail_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluent/cubit/teacher/lessons/lesson_detail_cubit.dart';
import 'package:fluent/data/models/test_model.dart';

class LessonDetailScreen extends StatefulWidget {
  final int lessonId;
  final String lessonTitle;

  const LessonDetailScreen({
    required this.lessonId,
    required this.lessonTitle,
  });

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<LessonDetailCubit>().loadLessonDetails(widget.lessonId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lessonTitle),
        elevation: 0,
      ),
      body: BlocBuilder<LessonDetailCubit, LessonDetailState>(
        builder: (context, state) {
          if (state is LessonDetailLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (state is LessonDetailError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text(state.message),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<LessonDetailCubit>()
                          .loadLessonDetails(widget.lessonId);
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is LessonDetailLoaded) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ معلومات الدرس
                  _buildLessonInfo(state.lesson),

                  SizedBox(height: 32),

                  // ✅ قسم الاختبارات
                  _buildTestsSection(context, state.tests),

                  SizedBox(height: 32),

                  // ✅ قسم التعليقات (إن وجدت)
                  if (state.comments.isNotEmpty)
                    _buildCommentsSection(state.comments),
                ],
              ),
            );
          }

          return SizedBox.expand(
            child: Center(child: Text('Unknown state')),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateTest(context),
        tooltip: 'Create Test',
        child: Icon(Icons.add),
      ),
    );
  }

  // ✅ بناء قسم معلومات الدرس
  Widget _buildLessonInfo(dynamic lesson) {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lesson Information',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 16),
          _infoRow('Title (EN)', lesson['title_en'] ?? '—'),
          _infoRow('Title (AR)', lesson['title_ar'] ?? '—'),
          _infoRow('Status', lesson['status']?.toString() ?? '—'),
          _infoRow('XP Points', lesson['xp_points']?.toString() ?? '—'),
          if (lesson['video'] != null)
            _infoRow('Video', 'Uploaded ✓'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // ✅ بناء قسم الاختبارات
  Widget _buildTestsSection(BuildContext context, List<TestModel> tests) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tests (${tests.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (tests.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _navigateToCreateTest(context),
                  icon: Icon(Icons.add),
                  label: Text('Add Test'),
                ),
            ],
          ),
          SizedBox(height: 16),
          if (tests.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No tests yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _navigateToCreateTest(context),
                      child: Text('Create First Test'),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: tests.length,
              itemBuilder: (context, index) {
                final test = tests[index];
                return _buildTestCard(context, test);
              },
            ),
        ],
      ),
    );
  }

  // ✅ بطاقة الاختبار
  Widget _buildTestCard(BuildContext context, TestModel test) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        test.titleEn,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        test.titleAr,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                _statusBadge(test.status),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                _testInfoChip('Questions', test.questions.length.toString()),
                SizedBox(width: 12),
                _testInfoChip(
                  'Passing Score',
                  '${test.passingScore}%',
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // ✅ زر الاطلاع
                TextButton.icon(
                  onPressed: () => _navigateToTestDetail(context, test.id),
                  icon: Icon(Icons.visibility),
                  label: Text('View'),
                ),
                SizedBox(width: 8),
                // ✅ زر التعديل (إذا كان ممكناً)
                if (test.canEdit)
                  TextButton.icon(
                    onPressed: () =>
                        _navigateToEditTest(context, test.id),
                    icon: Icon(Icons.edit),
                    label: Text('Edit'),
                  ),
                SizedBox(width: 8),
                // ✅ زر الحذف (إذا كان ممكناً)
                if (test.canDelete)
                  TextButton.icon(
                    onPressed: () => _confirmDeleteTest(context, test.id),
                    icon: Icon(Icons.delete, color: Colors.red),
                    label: Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ بطاقة معلومات الاختبار
  Widget _testInfoChip(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ✅ badge الحالة
  Widget _statusBadge(String status) {
    final colors = {
      'draft': Colors.grey,
      'pending': Colors.blue,
      'in_review': Colors.orange,
      'changes_requested': Colors.red,
      'approved': Colors.green[600],
      'published': Colors.green,
      'archived': Colors.grey[600],
      'closed': Colors.black,
    };

    final color = colors[status.toLowerCase()] ?? Colors.grey;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ✅ قسم التعليقات
  Widget _buildCommentsSection(List<dynamic> comments) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comments (${comments.length})',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: comments.length,
            itemBuilder: (context, index) {
              final comment = comments[index];
              return Card(
                margin: EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment['user']?['first_name'] ?? 'Anonymous',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(comment['comment'] ?? ''),
                      SizedBox(height: 4),
                      Text(
                        comment['created_at'] ?? '',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ✅ دوال الملاحة
  void _navigateToCreateTest(BuildContext context) {
    // الانتقال إلى شاشة إنشاء اختبار للدرس
    Navigator.of(context).pushNamed(
      '/test-form',
      arguments: {
        'testableType': 'lesson',
        'testableId': widget.lessonId,
        'action': 'create',
      },
    ).then((_) {
      // تحديث الاختبارات بعد الإنشاء
      context.read<LessonDetailCubit>().refreshTests(widget.lessonId);
    });
  }

  void _navigateToEditTest(BuildContext context, int testId) {
    Navigator.of(context).pushNamed(
      '/test-form',
      arguments: {
        'testId': testId,
        'action': 'edit',
      },
    ).then((_) {
      // تحديث الاختبارات بعد التعديل
      context.read<LessonDetailCubit>().refreshTests(widget.lessonId);
    });
  }

  void _navigateToTestDetail(BuildContext context, int testId) {
    Navigator.of(context).pushNamed(
      '/test-detail',
      arguments: {'testId': testId},
    );
  }

  void _confirmDeleteTest(BuildContext context, int testId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Test?'),
        content: Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<LessonDetailCubit>().deleteTest(testId);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}