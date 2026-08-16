import 'package:fluent/cubit/certificates/certificates_cubit.dart';
import 'package:fluent/cubit/contact_us/contact_us_cubit.dart';
import 'package:fluent/data/repository/certificate_repository.dart';
import 'package:fluent/data/repository/contact_us_repository.dart';
import 'package:fluent/presentation/screens/statics/certificates_screen.dart';
import 'package:fluent/presentation/screens/statics/contact_us_screen.dart';
import 'package:fluent/cubit/auth/forgot_password/forgot_password_cubit.dart';
import 'package:fluent/cubit/auth/reset_password/reset_password_cubit.dart';
import 'package:fluent/cubit/auth/verify_otp/verify_otp_cubit.dart';
import 'package:fluent/cubit/student/chat/chat_cubit.dart';
import 'package:fluent/cubit/teacher/courses/all/teacher_courses_cubit.dart';
import 'package:fluent/cubit/teacher/courses/delete/lesson_delete_cubit.dart';
import 'package:fluent/cubit/teacher/courses/details/teacher_course_detail_cubit.dart';
import 'package:fluent/cubit/teacher/courses/form/lesson_form_cubit.dart';
import 'package:fluent/cubit/teacher/home/home_teacher_cubit.dart';
import 'package:fluent/cubit/teacher/lessons/lesson_detail_cubit.dart';
import 'package:fluent/cubit/teacher/words/create/word_create_cubit.dart';
import 'package:fluent/cubit/teacher/words/update/word_update_cubit.dart';
import 'package:fluent/cubit/teacher/words/delete/word_delete_cubit.dart';
import 'package:fluent/data/models/level_exception_model.dart';
import 'package:fluent/data/repository/chat_repository.dart';
import 'package:fluent/data/repository/word_repository.dart';
import 'package:fluent/cubit/teacher/questions/list/question_list_cubit.dart';
import 'package:fluent/cubit/teacher/questions/question_filter/question_filter_cubit.dart';
import 'package:fluent/cubit/teacher/statuses/teacher_status_board_cubit.dart';
import 'package:fluent/cubit/teacher/content_review/content_review_cubit.dart';
import 'package:fluent/cubit/teacher/tests/create/test_create_cubit.dart';
import 'package:fluent/cubit/teacher/tests/delete/test_delete_cubit.dart';
import 'package:fluent/cubit/teacher/tests/update/test_update_cubit.dart';
import 'package:fluent/data/models/course_model.dart';
import 'package:fluent/data/models/lesson_model.dart';
import 'package:fluent/data/models/test_model.dart';
import 'package:fluent/data/repository/question_repository.dart';
import 'package:fluent/data/repository/lesson_repository.dart';
import 'package:fluent/data/repository/test_repository.dart';
import 'package:fluent/data/repository/content_review_repository.dart';
import 'package:fluent/presentation/screens/chat/chat_entry_screen.dart';
import 'package:fluent/presentation/screens/notifications/notifications_screen.dart';
import 'package:fluent/presentation/screens/teacher/courses/teacher_course_detail_screen.dart';
import 'package:fluent/presentation/screens/teacher/courses/teacher_courses_screen.dart';
import 'package:fluent/presentation/screens/teacher/courses/course_tests_screen.dart';
import 'package:fluent/presentation/screens/teacher/home/teacher_home_screen.dart';
import 'package:fluent/presentation/screens/teacher/stats/teacher_stats_screen.dart';
import 'package:fluent/cubit/teacher/stats/teacher_stats_cubit.dart';
import 'package:fluent/data/repository/teacher_stats_repository.dart';
import 'package:fluent/presentation/screens/teacher/lessons/lesson_detail_screen.dart';
import 'package:fluent/presentation/screens/teacher/lessons/lesson_form_screen.dart';
import 'package:fluent/presentation/screens/teacher/status_board/teacher_status_board_screen.dart';
import 'package:fluent/presentation/screens/Streak/StreakScreen.dart';
import 'package:fluent/presentation/screens/auth/OtpVerificationScreen.dart';
import 'package:fluent/presentation/screens/auth/forget_password_screen.dart';
import 'package:fluent/presentation/screens/auth/set_new_password_screen.dart';
import 'package:fluent/presentation/screens/home/student_home_screen.dart';

import 'package:fluent/presentation/screens/placement/placement_test_screen.dart';
import 'package:fluent/presentation/screens/placementTestDialog.dart';
import 'package:fluent/presentation/screens/teacher/questions/questions_list_screen.dart';
import 'package:fluent/presentation/screens/teacher/tests/test_detail_view_screen.dart';
import 'package:fluent/presentation/screens/teacher/tests/test_form_screen.dart';
import 'package:fluent/presentation/screens/test/student_test_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'constants/strings.dart';
import 'cubit/auth/sign_up/sign_up_cubit.dart';
import 'cubit/auth/login/login_cubit.dart';
import 'cubit/auth/resend_otp/resend_otp_cubit.dart';
import 'data/repository/auth_repository.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/courses/level_courses_screen.dart';
import 'package:fluent/presentation/screens/statics/profile_screen.dart';
import 'package:fluent/cubit/profile/profile_cubit.dart';
import 'package:fluent/data/repository/profile_repository.dart';
import 'package:fluent/presentation/screens/statics/word_bank_screen.dart';
import 'package:fluent/presentation/screens/statics/podcasts_screen.dart';
import 'package:fluent/presentation/screens/statics/ai_conversation_screen.dart';
import 'package:fluent/cubit/student/levels/levels_cubit.dart';
import 'package:fluent/data/repository/level_repository.dart';
import 'package:fluent/cubit/student/courses/course_cubit.dart';
import 'package:fluent/data/repository/course_repository.dart';
import 'package:fluent/cubit/student/lessons/lesson_detail_cubit.dart'
    as student_lesson;
import 'package:fluent/data/repository/lesson_detail_repository.dart';
import 'package:fluent/presentation/screens/lessons/lesson_detail_screen.dart'
    as student_lesson_screen;
import 'package:fluent/cubit/student/levels/level_exception_cubit.dart';
import 'package:fluent/data/repository/level_exception_repository.dart';
import 'package:fluent/presentation/screens/statics/level_exception_screen.dart';
import 'package:fluent/cubit/student/levels/level_exception_details_cubit.dart';
import 'package:fluent/presentation/screens/statics/level_exception_details_screen.dart';
import 'package:fluent/cubit/student/levels/level_exception_delete_cubit.dart';
import 'package:fluent/data/repository/level_exception_repository.dart';
import 'package:fluent/cubit/student/words_bank/words_bank_cubit.dart';
import 'package:fluent/data/repository/words_bank_repository.dart';
import 'package:fluent/cubit/student/lesson_words/lesson_words_cubit.dart';
import 'package:fluent/data/repository/lesson_word_repository.dart';
import 'package:fluent/cubit/student/podcasts/podcast_topics_cubit.dart';
import 'package:fluent/cubit/student/podcasts/topic_podcasts_cubit.dart';
import 'package:fluent/data/repository/podcast_repository.dart';
import 'package:fluent/cubit/student/podcasts/podcast_detail_cubit.dart';
import 'package:fluent/presentation/screens/statics/podcast_detail_screen.dart';

class AppRouter {
  final AuthRepository authRepository;

  AppRouter(this.authRepository);

  Route<dynamic>? generateRoute(RouteSettings settings) {
    print("🧭 [AppRouter] Generating route: ${settings.name}");

    switch (settings.name) {
      case onboardingRoute:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());

      case loginRoute:
        final email = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => LoginCubit(authRepository),
            child: LoginScreen(email: email),
          ),
        );

      case registerRoute:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => SignUpCubit(authRepository),
            child: const RegisterScreen(),
          ),
        );

      case otpRoute:
        final args = settings.arguments;
        String email = '';
        String type = OtpType.register;

        if (args is String) {
          email = args;
        } else if (args is Map<String, dynamic>) {
          email = args['email'] as String? ?? '';
          type = args['type'] as String? ?? OtpType.register;
        }

        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => VerifyOtpCubit(authRepository)),
              BlocProvider(create: (_) => ResendOtpCubit(authRepository)),
            ],
            child: OtpVerificationScreen(email: email, type: type),
          ),
        );

      case forgotPasswordRoute:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => ForgotPasswordCubit(authRepository),
            child: const ForgetPasswordScreen(),
          ),
        );

      case setNewPasswordRoute:
        final email = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => ResetPasswordCubit(authRepository),
            child: const SetNewPasswordScreen(),
          ),
          settings: RouteSettings(arguments: email),
        );

      case streakRoute:
        return MaterialPageRoute(builder: (_) => const StreakScreen());

      case placementTestRoute:
        return MaterialPageRoute(
          builder: (_) => const PlacementTestScreen(showIntro: true),
        );

      case studentTestRoute:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        final testId = args['testId'] as int? ?? 0;
        final title = args['title'] as String?;
        final xpRaw = args['xpPoints'];
        final xpPoints = xpRaw is int
            ? xpRaw
            : int.tryParse(xpRaw?.toString() ?? '') ?? 0;
        return MaterialPageRoute(
          builder: (_) => StudentTestScreen(
            testId: testId,
            title: title,
            xpPoints: xpPoints,
          ),
        );

      case placementTestDialogRoute:
        return MaterialPageRoute(builder: (_) => const PlacementTestDialog());

      case homeRoute:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case studentHomeRoute:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (ctx) =>
                StudentLevelsCubit(ctx.read<LevelRepository>())
                  ..fetchStudentLevels(),
            child: const StudentHomeScreen(),
          ),
        );

      case profileRoute:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (ctx) => ProfileCubit(
              profileRepository: ctx.read<ProfileRepository>(),
              authRepository: ctx.read<AuthRepository>(),
            )..loadProfile(),
            child: const ProfileScreen(),
          ),
        );

      case wordBankRoute:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (ctx) =>
                WordsBankCubit(ctx.read<WordsBankRepository>())..fetchAll(),
            child: const WordBankScreen(),
          ),
        );

      case podcastsRoute:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (ctx) =>
                PodcastTopicsCubit(ctx.read<PodcastRepository>())
                  ..fetchTopics(),
            child: const PodcastsScreen(),
          ),
        );
      case podcastDetailRoute:
        final args = settings.arguments as Map<String, dynamic>;
        final int podcastId = args['podcastId'] as int;
        final String podcastTitle = args['title'] as String? ?? '';

        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (ctx) =>
                PodcastDetailCubit(ctx.read<PodcastRepository>())
                  ..fetchDetails(podcastId),
            child: PodcastDetailScreen(
              podcastId: podcastId,
              podcastTitle: podcastTitle,
            ),
          ),
        );

      case aiConversationRoute:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (ctx) => ChatCubit(ctx.read<ChatRepository>())..bootstrap(),
            child: const ChatEntryScreen(),
          ),
        );

      case teacherHomeRoute:
        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (ctx) => TeacherHomeCubit(
                  ctx.read<LessonRepository>(),
                  ctx.read<QuestionRepository>(),
                  ctx.read<TestRepository>(),
                )..loadDashboardData(),
              ),
            ],
            child: const TeacherHomeScreen(),
          ),
        );

      case teacherStatsRoute:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (ctx) => TeacherStatsCubit(
              statsRepository: ctx.read<TeacherStatsRepository>(),
              lessonRepository: ctx.read<LessonRepository>(),
              testRepository: ctx.read<TestRepository>(),
            ),
            child: const TeacherStatsScreen(),
          ),
        );

      case levelCoursesRoute:
        final args = settings.arguments as Map<String, dynamic>;
        final levelId = args['levelId'] as int?;

        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (ctx) =>
                StudentCoursesCubit(ctx.read<CourseRepository>())
                  ..fetchStudentCourses(levelId ?? 0),
            child: LevelCoursesScreen(
              levelId: levelId,
              testId: args['testId'] as int?,
              userName: args['userName'] as String? ?? "Rasha",
              xp: args['xp'] as int? ?? 12540,
              streakDays: args['streakDays'] as int? ?? 15,
              level: args['level'] as int? ?? 8,
              levelProgress: args['levelProgress'] as double? ?? 0.78,
              levelTitle: args['levelTitle'] as String? ?? "Level 8",
              levelSubtitle:
                  args['levelSubtitle'] as String? ?? "Grammar Mastery",
            ),
          ),
        );

      case lessonStudentDetailRoute:
        final args = settings.arguments as Map<String, dynamic>;
        final lessonId = args['lessonId'] as int?;

        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (ctx) => student_lesson.LessonDetailCubit(
                  ctx.read<LessonDetailRepository>(),
                )..fetchLessonDetail(lessonId ?? 0),
              ),
              BlocProvider(
                create: (ctx) =>
                    LessonWordsCubit(ctx.read<LessonWordRepository>()),
              ),
            ],
            child: student_lesson_screen.LessonDetailScreen(
              lessonId: lessonId,
              lessonTitle: args['lessonTitle'] as String? ?? '',
            ),
          ),
        );

      case levelExceptionsRoute:
        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (ctx) =>
                    LevelExceptionCubit(ctx.read<LevelExceptionRepository>()),
              ),
              BlocProvider(
                create: (ctx) => LevelExceptionDeleteCubit(
                  ctx.read<LevelExceptionRepository>(),
                ),
              ),
            ],
            child: const LevelExceptionsScreen(),
          ),
        );

      case levelExceptionDetailsRoute:
        final args = settings.arguments as Map<String, dynamic>;
        final int exceptionId = args['id'] as int;
        final LevelExceptionModel? seed = args['seed'] is LevelExceptionModel
            ? args['seed'] as LevelExceptionModel
            : null;

        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (ctx) => LevelExceptionDetailsCubit(
              ctx.read<LevelExceptionRepository>(),
              seed: seed,
            )..fetchDetails(exceptionId),
            child: LevelExceptionDetailsScreen(exceptionId: exceptionId),
          ),
        );

      case questionsListRoute:
        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (ctx) =>
                    QuestionListCubit(ctx.read<QuestionRepository>())
                      ..loadInitial(),
              ),
              BlocProvider(
                create: (ctx) =>
                    QuestionFilterCubit(ctx.read<QuestionRepository>()),
              ),
            ],
            child: const QuestionsListScreen(),
          ),
        );

      case teacherStatusBoardRoute:
        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (ctx) => TeacherStatusBoardCubit(
                  ctx.read<LessonRepository>(),
                  ctx.read<TestRepository>(),
                )..loadAll(),
              ),
              BlocProvider(
                create: (ctx) =>
                    ContentReviewCubit(ctx.read<ContentReviewRepository>()),
              ),
            ],
            child: const TeacherStatusBoardScreen(),
          ),
        );

      case teacherCoursesRoute:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (ctx) =>
                TeacherCoursesCubit(ctx.read<LessonRepository>())
                  ..loadCourses(),
            child: const TeacherCoursesScreen(),
          ),
        );

      case teacherCourseDetailRoute:
        final args = settings.arguments;

        if (args is CourseModel) {
          return MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (ctx) => TeacherCourseDetailCubit(
                ctx.read<LessonRepository>(),
                ctx.read<TestRepository>(),
                args,
              )..loadLessons(),
              child: TeacherCourseDetailScreen(course: args),
            ),
          );
        } else {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text(
                  'Error: Course data is missing or invalid',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          );
        }

      case lessonFormRoute:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (ctx) => LessonFormCubit(ctx.read<LessonRepository>()),
              ),
              BlocProvider(
                create: (ctx) =>
                    LessonDeleteCubit(ctx.read<LessonRepository>()),
              ),
              BlocProvider(
                create: (ctx) => TestDeleteCubit(ctx.read<TestRepository>()),
              ),
              BlocProvider(
                create: (ctx) => WordCreateCubit(ctx.read<WordRepository>()),
              ),
              BlocProvider(
                create: (ctx) => WordUpdateCubit(ctx.read<WordRepository>()),
              ),
              BlocProvider(
                create: (ctx) => WordDeleteCubit(ctx.read<WordRepository>()),
              ),
            ],
            child: LessonFormScreen(
              courseId: args['courseId'] as int?,
              lesson: args['lesson'] as LessonModel?,
              courseStatus: args['courseStatus'] as String?,
            ),
          ),
        );

      case lessonDetailRoute:
        final args = settings.arguments as Map<String, dynamic>;
        final int lessonId = args['lessonId'] as int;
        final String lessonTitle = args['lessonTitle'] as String? ?? 'Lesson';

        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (ctx) => LessonDetailCubit(
                  lessonRepository: ctx.read<LessonRepository>(),
                  testRepository: ctx.read<TestRepository>(),
                  lessonDetailRepository: ctx.read<LessonDetailRepository>(),
                )..loadLessonDetails(lessonId),
              ),
              BlocProvider(
                create: (ctx) =>
                    LessonDeleteCubit(ctx.read<LessonRepository>()),
              ),
              BlocProvider(
                create: (ctx) =>
                    ContentReviewCubit(ctx.read<ContentReviewRepository>()),
              ),
            ],
            child: LessonDetailScreen(
              lessonId: lessonId,
              lessonTitle: lessonTitle,
            ),
          ),
        );

      case testFormRoute:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (ctx) => TestCreateCubit(ctx.read<TestRepository>()),
              ),
              BlocProvider(
                create: (ctx) => TestUpdateCubit(ctx.read<TestRepository>()),
              ), // ✅ جديد
              BlocProvider(
                create: (ctx) =>
                    QuestionFilterCubit(ctx.read<QuestionRepository>()),
              ),
            ],
            child: TestFormScreen(
              testableType: args['testableType'] as String,
              testableId: args['testableId'] as int,
              title: args['title'] as String,
              initialTest: args['initialTest'] as TestModel?, // ✅ جديد
            ),
          ),
        );

      case testDetailViewRoute:
        final args = settings.arguments as Map<String, dynamic>;
        final int testId = args['testId'] as int;
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (ctx) =>
                ContentReviewCubit(ctx.read<ContentReviewRepository>()),
            child: TestDetailViewScreen(testId: testId),
          ),
        );

      case courseTestsRoute:
        final args = settings.arguments as Map<String, dynamic>;
        final course = args['course'] as CourseModel;
        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (ctx) => TestDeleteCubit(ctx.read<TestRepository>()),
              ),
            ],
            child: CourseTestsScreen(course: course),
          ),
        );

      case notificationsRoute:
        // NotificationCubit is provided globally in main.dart
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());

      case certificatesRoute:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (ctx) =>
                CertificatesCubit(ctx.read<CertificateRepository>()),
            child: const CertificatesScreen(),
          ),
        );

      case contactUsRoute:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (ctx) => ContactUsCubit(ctx.read<ContactUsRepository>()),
            child: const ContactUsScreen(),
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(child: Text('Page not found')),
          ),
        );
    }
  }
}
