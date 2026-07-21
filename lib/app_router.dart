import 'package:fluent/cubit/auth/forgot_password/forgot_password_cubit.dart';
import 'package:fluent/cubit/auth/reset_password/reset_password_cubit.dart';
import 'package:fluent/cubit/auth/verify_otp/verify_otp_cubit.dart';
import 'package:fluent/cubit/teacher/courses/all/teacher_courses_cubit.dart';
import 'package:fluent/cubit/teacher/courses/delete/lesson_delete_cubit.dart';
import 'package:fluent/cubit/teacher/courses/details/teacher_course_detail_cubit.dart';
import 'package:fluent/cubit/teacher/courses/form/lesson_form_cubit.dart';
import 'package:fluent/cubit/teacher/home/home_teacher_cubit.dart';
import 'package:fluent/cubit/teacher/questions/list/question_list_cubit.dart';
import 'package:fluent/cubit/teacher/statuses/teacher_status_board_cubit.dart';
import 'package:fluent/data/models/course_model.dart';
import 'package:fluent/data/models/lesson_model.dart';
import 'package:fluent/data/repository/question_repository.dart';
import 'package:fluent/data/repository/lesson_repository.dart';
import 'package:fluent/presentation/screens/teacher/courses/teacher_course_detail_screen.dart';
import 'package:fluent/presentation/screens/teacher/courses/teacher_courses_screen.dart';
import 'package:fluent/presentation/screens/teacher/home/teacher_home_screen.dart';
import 'package:fluent/presentation/screens/teacher/lessons/lesson_form_screen.dart';
import 'package:fluent/presentation/screens/teacher/status_board/teacher_status_board_screen.dart';
import 'package:fluent/presentation/screens/Streak/StreakScreen.dart';
import 'package:fluent/presentation/screens/auth/OtpVerificationScreen.dart';
import 'package:fluent/presentation/screens/auth/forget_password_screen.dart';
import 'package:fluent/presentation/screens/auth/set_new_password_screen.dart';
import 'package:fluent/presentation/screens/home/student_home_screen.dart';
import 'package:fluent/presentation/screens/home/teacher_home_screen.dart';

import 'package:fluent/presentation/screens/placement/placement_test_screen.dart';
import 'package:fluent/presentation/screens/placementTestDialog.dart';
import 'package:fluent/presentation/screens/teacher/questions/questions_list_screen.dart';
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
import 'package:fluent/presentation/screens/statics/word_bank_screen.dart';
import 'package:fluent/presentation/screens/statics/podcasts_screen.dart';
import 'package:fluent/presentation/screens/statics/ai_conversation_screen.dart';
import 'package:fluent/cubit/student/levels/levels_cubit.dart';
import 'package:fluent/data/repository/level_repository.dart';
import 'package:fluent/cubit/student/courses/course_cubit.dart';
import 'package:fluent/data/repository/course_repository.dart';

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
        return MaterialPageRoute(builder: (_) => const ProfileScreen());

      case wordBankRoute:
        return MaterialPageRoute(builder: (_) => const WordBankScreen());

      case podcastsRoute:
        return MaterialPageRoute(builder: (_) => const PodcastsScreen());

      case aiConversationRoute:
        return MaterialPageRoute(builder: (_) => const AIConversationScreen());

      case teacherHomeRoute:
        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (ctx) => TeacherHomeCubit(
                  ctx.read<LessonRepository>(),
                  ctx.read<QuestionRepository>(),
                )..loadDashboardData(), // جلب البيانات فور فتح الشاشة
              ),
            ],
            child: const TeacherHomeScreen(), // لم نعد نحتاج لتمرير متغيرات
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

      // ✅ Teacher: Questions list
      case questionsListRoute:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (ctx) => QuestionListCubit(ctx.read<QuestionRepository>()),
            child: const QuestionsListScreen(),
          ),
        );

      // ✅ Teacher: Lesson status board (teacher's home screen)
      // ✅ Teacher: Status Board
      case teacherStatusBoardRoute: // يمكنك تغيير اسم الـ route الثابت في strings.dart إلى teacherStatusBoardRoute
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (ctx) =>
                TeacherStatusBoardCubit(ctx.read<LessonRepository>())
                  ..loadAll(),
            child: const TeacherStatusBoardScreen(),
          ),
        );

      // ✅ Teacher: All Courses Library
      case teacherCoursesRoute:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (ctx) =>
                TeacherCoursesCubit(ctx.read<LessonRepository>())
                  ..loadCourses(),
            child: const TeacherCoursesScreen(),
          ),
        );

      // ✅ Teacher: Course Details (يستقبل كائن CourseModel بأمان)
      case teacherCourseDetailRoute:
        final args = settings.arguments;

        // فحص آمن لنوع البيانات لمنع الأخطاء
        if (args is CourseModel) {
          return MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (ctx) =>
                  TeacherCourseDetailCubit(ctx.read<LessonRepository>(), args)
                    ..loadLessons(),
              child: TeacherCourseDetailScreen(course: args),
            ),
          );
        } else {
          // في حال تم تمرير بيانات خاطئة، نعرض شاشة خطأ بدلاً من انهيار التطبيق
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              body: Center(
                child: Text(
                  'Error: Course data is missing or invalid',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          );
        }

      // ✅ Teacher: Lesson Form (Create / Edit)

      // في ملف AppRouter.dart

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
            ],
            child: LessonFormScreen(
              courseId: args['courseId'] as int?,
              lesson: args['lesson'] as LessonModel?,
              courseStatus:
                  args['courseStatus'] as String?, // ✅ استقبال حالة الكورس
            ),
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
