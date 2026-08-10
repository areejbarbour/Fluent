import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fluent/cubit/auth/forgot_password/forgot_password_cubit.dart';
import 'package:fluent/cubit/auth/google_sign_in/google_sign_in_cubit.dart';
import 'package:fluent/cubit/auth/login/login_cubit.dart';
import 'package:fluent/cubit/auth/logout/logout_cubit.dart';
import 'package:fluent/cubit/auth/resend_otp/resend_otp_cubit.dart';
import 'package:fluent/cubit/auth/reset_password/reset_password_cubit.dart';
import 'package:fluent/cubit/auth/sign_up/sign_up_cubit.dart';
import 'package:fluent/cubit/auth/verify_otp/verify_otp_cubit.dart';
import 'package:fluent/data/network/dio_client.dart';
import 'package:fluent/data/repository/attempt_repository.dart';
import 'package:fluent/data/repository/auth_repository.dart';
import 'package:fluent/data/repository/profile_repository.dart';
import 'package:fluent/data/services/attempt_service.dart';
import 'package:fluent/data/services/profile_service.dart';
import 'package:fluent/data/repository/question_repository.dart';
import 'package:fluent/data/repository/lesson_repository.dart';
import 'package:fluent/data/repository/test_repository.dart';
import 'package:fluent/data/services/auth_service.dart';
import 'package:fluent/data/services/question_service.dart';
import 'package:fluent/data/services/lesson_service.dart';
import 'package:fluent/data/services/test_service.dart';
import 'package:fluent/data/services/content_review_service.dart';
import 'package:fluent/data/repository/content_review_repository.dart';
import 'package:fluent/data/services/notification_service.dart';
import 'package:fluent/data/repository/notification_repository.dart';
import 'package:fluent/cubit/notification/notification_cubit.dart';
import 'package:fluent/helper/local_notifications_service.dart';
import 'package:fluent/helper/notification_bootstrap.dart';
import 'package:fluent/helper/notification_route_resolver.dart';
import 'package:fluent/helper/nav_key.dart';
import 'package:fluent/data/models/notification_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluent/cubit/student/levels/levels_cubit.dart';
import 'package:fluent/data/repository/level_repository.dart';
import 'package:fluent/data/models/level_model.dart';
import 'package:fluent/data/services/level_service.dart';
import 'package:fluent/data/services/course_service.dart';
import 'package:fluent/data/repository/course_repository.dart';
import 'app_router.dart';
import 'package:fluent/helper/student_entry_navigator.dart';
import 'constants/strings.dart';
import 'package:fluent/data/services/student_lesson_service.dart';
import 'package:fluent/data/repository/student_lesson_repository.dart';
import 'package:fluent/data/repository/lesson_detail_repository.dart';
import 'package:fluent/data/services/lesson_detail_service.dart';
import 'package:fluent/data/services/word_service.dart';
import 'package:fluent/data/repository/word_repository.dart';
import 'package:fluent/data/services/level_exception_service.dart';
import 'package:fluent/data/repository/level_exception_repository.dart';
import 'package:fluent/data/services/words_bank_service.dart';
import 'package:fluent/data/repository/words_bank_repository.dart';
import 'package:fluent/data/services/lesson_word_service.dart';
import 'package:fluent/data/repository/lesson_word_repository.dart';
import 'package:fluent/data/services/rate_service.dart';
import 'package:fluent/data/repository/rate_repository.dart';
import 'package:fluent/data/services/word_quiz_service.dart';
import 'package:fluent/data/repository/word_quiz_repository.dart';

/// Handler للإشعارات عندما التطبيق في الخلفية أو مغلق.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await LocalNotificationsService.instance.init();
  print(
    '📩 [BG] message id=${message.messageId} title=${message.notification?.title}',
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase init (يجب قبل أي استخدام لـ FCM) ──
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // طلب إذن الإشعارات مبكراً (Android 13+ / iOS)
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

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

  final testService = TestService(dioInstance);
  final testRepository = TestRepository(testService);

  final studentLessonService = StudentLessonService(dioInstance);
  final studentLessonRepository = StudentLessonRepository(studentLessonService);

  final lessonDetailService = LessonDetailService(dioInstance);
  final lessonDetailRepository = LessonDetailRepository(lessonDetailService);

  final levelExceptionService = LevelExceptionService(dioInstance);
  final levelExceptionRepository = LevelExceptionRepository(
    levelExceptionService,
  );

  final wordService = WordService(dioInstance);
  final wordRepository = WordRepository(wordService);

  final wordsBankService = WordsBankService(dioInstance);
  final wordsBankRepository = WordsBankRepository(wordsBankService);

  final lessonWordService = LessonWordService(dioInstance);
  final lessonWordRepository = LessonWordRepository(lessonWordService);

  final rateService = RateService(dioInstance);
  final rateRepository = RateRepository(rateService);

  final wordQuizService = WordQuizService(dioInstance);
  final wordQuizRepository = WordQuizRepository(wordQuizService);

  final profileService = ProfileService(dioInstance);
  final profileRepository = ProfileRepository(profileService);

  final attemptService = AttemptService(dioInstance);
  final attemptRepository = AttemptRepository(attemptService);

  final contentReviewService = ContentReviewService(dioInstance);
  final contentReviewRepository = ContentReviewRepository(contentReviewService);

  final notificationService = NotificationService(dioInstance);
  final notificationRepository = NotificationRepository(notificationService);

  String initialRoute = onboardingRoute;
  if (isUserLoggedIn) {
    if (userRole == 'teacher') {
      initialRoute = teacherHomeRoute;
    } else {
      final placed =
          await StudentEntryNavigator.hasCompletedPlacementStandalone(
            levelRepository,
          );
      initialRoute = placed ? studentHomeRoute : placementTestDialogRoute;
      print('🔍 [main] student placed=$placed → $initialRoute');
    }
  }

  runApp(
    MyApp(
      authRepository: authRepository,
      questionRepository: questionRepository,
      levelRepository: levelRepository,
      courseRepository: courseRepository,
      lessonRepository: lessonRepository,
      testRepository: testRepository,
      studentLessonRepository: studentLessonRepository,
      lessonDetailRepository: lessonDetailRepository,
      wordRepository: wordRepository,
      levelExceptionRepository: levelExceptionRepository,
      wordsBankRepository: wordsBankRepository,
      lessonWordRepository: lessonWordRepository,
      rateRepository: rateRepository,
      wordQuizRepository: wordQuizRepository,
      profileRepository: profileRepository,
      attemptRepository: attemptRepository,
      contentReviewRepository: contentReviewRepository,
      notificationRepository: notificationRepository,
      initialRoute: initialRoute,
      isUserLoggedIn: isUserLoggedIn,
    ),
  );
}

class MyApp extends StatefulWidget {
  final AuthRepository authRepository;
  final QuestionRepository questionRepository;
  final LevelRepository levelRepository;
  final CourseRepository courseRepository;
  final LessonRepository lessonRepository;
  final TestRepository testRepository;
  final StudentLessonRepository studentLessonRepository;
  final LessonDetailRepository lessonDetailRepository;
  final WordRepository wordRepository;
  final String initialRoute;
  final LevelExceptionRepository levelExceptionRepository;
  final WordsBankRepository wordsBankRepository;
  final LessonWordRepository lessonWordRepository;
  final RateRepository rateRepository;
  final WordQuizRepository wordQuizRepository;
  final ProfileRepository profileRepository;
  final AttemptRepository attemptRepository;
  final ContentReviewRepository contentReviewRepository;
  final NotificationRepository notificationRepository;
  final bool isUserLoggedIn;
  late final AppRouter appRouter;

  MyApp({
    super.key,
    required this.authRepository,
    required this.questionRepository,
    required this.levelRepository,
    required this.courseRepository,
    required this.lessonRepository,
    required this.testRepository,
    required this.studentLessonRepository,
    required this.lessonDetailRepository,
    required this.wordRepository,
    required this.initialRoute,
    required this.levelExceptionRepository,
    required this.wordsBankRepository,
    required this.lessonWordRepository,
    required this.rateRepository,
    required this.wordQuizRepository,
    required this.profileRepository,
    required this.attemptRepository,
    required this.contentReviewRepository,
    required this.notificationRepository,
    this.isUserLoggedIn = false,
  }) {
    appRouter = AppRouter(authRepository);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // Uses the shared global `navigatorKey` from helper/nav_key.dart so
  // LocalNotificationsService can also navigate from outside the widget tree.

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupForegroundMessaging();
    WidgetsBinding.instance.addPostFrameCallback((_) => _onAppReady());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // رجع من الخلفية → حدّث فوراً + تأكيد تسجيل التوكن
      _refreshNotifications();
      _ensureFcmRegistered();
    }
  }

  Future<void> _onAppReady() async {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;

    // Listen for FCM token rotation for the whole app lifetime
    NotificationBootstrap.listenTokenRefresh();

    if (widget.isUserLoggedIn) {
      // تسجيل FCM token عند فتح التطبيق (جلسة سابقة)
      await NotificationBootstrap.registerFromContext(ctx);
      await NotificationBootstrap.refreshUnread(ctx);
    }
  }

  Future<void> _ensureFcmRegistered() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null || token.isEmpty) return;
      await NotificationBootstrap.registerAfterAuth();
    } catch (e) {
      print('⚠️ [FCM] ensure registered: $e');
    }
  }

  /// استماع الإشعارات والتطبيق مفتوح (Foreground)
  void _setupForegroundMessaging() {
    // التطبيق مفتوح → إشعار جديد
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('📩 [FG] ${message.notification?.title}');

      // إشعار حقيقي أعلى الشاشة (اسم التطبيق + أيقونة)
      await LocalNotificationsService.instance.showFromFirebase(message);

      // تحديث العداد والقائمة
      _refreshNotifications();
    });

    // ضغط على الإشعار من الخلفية
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📩 [Opened] ${message.messageId}');
      _refreshNotifications();
      _openFromMessage(message);
    });

    // فتح التطبيق من إشعار وهو كان مغلقاً
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshNotifications();
        _openFromMessage(message);
      });
    });
  }

  /// يفتح الصفحة المناسبة حسب نوع وبيانات الإشعار (نفس منطق التوجيه
  /// المستخدم داخل شاشة الإشعارات وعند الضغط من شريط النظام).
  void _openFromMessage(RemoteMessage message) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;

    final type =
        message.data['type']?.toString() ?? AppNotificationModel.typeGeneral;

    NotificationRouteResolver.open(
      ctx,
      type: type,
      data: message.data,
      fallbackTitle: message.notification?.title,
    );
  }

  void _refreshNotifications() {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) {
      print('⚠️ [FCM] context is null — skip refresh');
      return;
    }
    try {
      print('🔄 [FCM] calling refreshAll()');
      ctx.read<NotificationCubit>().refreshAll();
    } catch (e, st) {
      print('❌ [FCM] refreshAll error: $e');
      print(st);
    }
  }

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
            ),
            RepositoryProvider<CourseRepository>.value(
              value: widget.courseRepository,
            ),
            RepositoryProvider<LessonRepository>.value(
              value: widget.lessonRepository,
            ),
            RepositoryProvider<TestRepository>.value(
              value: widget.testRepository,
            ),
            RepositoryProvider<StudentLessonRepository>.value(
              value: widget.studentLessonRepository,
            ),
            RepositoryProvider<LessonDetailRepository>.value(
              value: widget.lessonDetailRepository,
            ),
            RepositoryProvider<WordRepository>.value(
              value: widget.wordRepository,
            ),
            RepositoryProvider<LevelExceptionRepository>.value(
              value: widget.levelExceptionRepository,
            ),
            RepositoryProvider<WordsBankRepository>.value(
              value: widget.wordsBankRepository,
            ),
            RepositoryProvider<LessonWordRepository>.value(
              value: widget.lessonWordRepository,
            ),
            RepositoryProvider<RateRepository>.value(
              value: widget.rateRepository,
            ),
            RepositoryProvider<WordQuizRepository>.value(
              value: widget.wordQuizRepository,
            ),
            RepositoryProvider<ProfileRepository>.value(
              value: widget.profileRepository,
            ),
            RepositoryProvider<AttemptRepository>.value(
              value: widget.attemptRepository,
            ),
            RepositoryProvider<ContentReviewRepository>.value(
              value: widget.contentReviewRepository,
            ),
            RepositoryProvider<NotificationRepository>.value(
              value: widget.notificationRepository,
            ),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) =>
                    NotificationCubit(widget.notificationRepository)
                      ..loadUnreadCount(),
              ),
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
