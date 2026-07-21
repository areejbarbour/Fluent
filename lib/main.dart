import 'package:dio/dio.dart';
import 'package:fluent/cubit/auth/forgot_password/forgot_password_cubit.dart';
import 'package:fluent/cubit/auth/google_sign_in/google_sign_in_cubit.dart';
import 'package:fluent/cubit/auth/login/login_cubit.dart';
import 'package:fluent/cubit/auth/logout/logout_cubit.dart';
import 'package:fluent/cubit/auth/resend_otp/resend_otp_cubit.dart';
import 'package:fluent/cubit/auth/reset_password/reset_password_cubit.dart';
import 'package:fluent/cubit/auth/sign_up/sign_up_cubit.dart';
import 'package:fluent/cubit/auth/verify_otp/verify_otp_cubit.dart';
import 'package:fluent/data/network/dio_client.dart';
import 'package:fluent/data/repository/auth_repository.dart';
import 'package:fluent/data/repository/question_repository.dart';
import 'package:fluent/data/repository/lesson_repository.dart';
import 'package:fluent/data/services/auth_service.dart';
import 'package:fluent/data/services/question_service.dart';
import 'package:fluent/data/services/lesson_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluent/cubit/student/levels/levels_cubit.dart';
import 'package:fluent/data/repository/level_repository.dart';
import 'package:fluent/data/services/level_service.dart';
import 'package:fluent/data/services/course_service.dart';
import 'package:fluent/data/repository/course_repository.dart';
import 'app_router.dart';
import 'constants/strings.dart';

// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDio();

  final prefs = await SharedPreferences.getInstance();
  final bool isUserLoggedIn = prefs.getBool('is_logged_in') ?? false;

  final String? userRole = prefs.getString('user_role');

  print("🔍 [main] isUserLoggedIn: $isUserLoggedIn");
  print("🔍 [main] userRole: $userRole");

  final Dio dioInstance = dio;
  final authService = AuthService(dioInstance);
  final authRepository = AuthRepository(authService);

  final questionService = QuestionService(dioInstance);
  final questionRepository = QuestionRepository(questionService);

  final lessonService = LessonService(dioInstance);
  final lessonRepository = LessonRepository(lessonService);

  final levelService = LevelService(dioInstance);
  final levelRepository = LevelRepository(levelService);

  final courseService = CourseService(dioInstance);
  final courseRepository = CourseRepository(courseService);

  String initialRoute = onboardingRoute;

  if (isUserLoggedIn) {
    if (userRole == 'teacher') {
      initialRoute = teacherHomeRoute; // 🎓 صفحة المعلم (لوحة حالات الدروس)
    } else {
      initialRoute = studentHomeRoute; // 🎓 صفحة الطالب
    }
  }

  runApp(
    MyApp(
      authRepository: authRepository,
      questionRepository: questionRepository,
      levelRepository: levelRepository,
      courseRepository: courseRepository,
      lessonRepository: lessonRepository,
      initialRoute: initialRoute,
    ),
  );
}

class MyApp extends StatefulWidget {
  final AuthRepository authRepository;
  final QuestionRepository questionRepository;
  final LevelRepository levelRepository;
  final CourseRepository courseRepository; // ✅ جديد
  final LessonRepository lessonRepository; // ✅ جديد
  final String initialRoute;
  late final AppRouter appRouter;

  MyApp({
    super.key,
    required this.authRepository,
    required this.questionRepository,
    required this.levelRepository,
    required this.courseRepository, // ✅ جديد
    required this.lessonRepository, // ✅ جديد
    required this.initialRoute,
  }) {
    appRouter = AppRouter(authRepository);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiRepositoryProvider(
          providers: [
            RepositoryProvider<AuthRepository>.value(
              value: widget.authRepository,
            ),
            RepositoryProvider<QuestionRepository>.value(
              value: widget.questionRepository,
            ),
            RepositoryProvider<LevelRepository>.value(
              value: widget.levelRepository,
            ), // ✅ جديد
            RepositoryProvider<CourseRepository>.value(
              value: widget.courseRepository,
            ),
            RepositoryProvider<LessonRepository>.value(
              value: widget.lessonRepository,
            ),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => SignUpCubit(widget.authRepository)),
              BlocProvider(create: (_) => LoginCubit(widget.authRepository)),
              BlocProvider(
                create: (_) => VerifyOtpCubit(widget.authRepository),
              ),
              BlocProvider(
                create: (_) => ResendOtpCubit(widget.authRepository),
              ),
              BlocProvider(create: (_) => LogoutCubit(widget.authRepository)),

              BlocProvider(
                create: (_) => ForgotPasswordCubit(widget.authRepository),
              ),
              BlocProvider(
                create: (_) => ResetPasswordCubit(widget.authRepository),
              ),

              BlocProvider(
                create: (_) => GoogleLoginCubit(widget.authRepository),
              ),

              BlocProvider(
                create: (_) => StudentLevelsCubit(widget.levelRepository),
              ),
            ],
            child: MaterialApp(
              title: 'Fluent',
              debugShowCheckedModeBanner: false,
              navigatorKey: navigatorKey,
              theme: ThemeData(
                useMaterial3: true,
                primarySwatch: Colors.blue,
                scaffoldBackgroundColor: Colors.transparent,
              ),
              initialRoute: widget.initialRoute,
              onGenerateRoute: widget.appRouter.generateRoute,
            ),
          ),
        );
      },
    );
  }
}
