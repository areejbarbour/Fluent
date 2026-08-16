import 'package:dio/dio.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fluent/data/repository/chat_repository.dart';
import 'package:fluent/data/services/chat_service.dart';
import 'package:fluent/data/services/progress_service.dart';
import 'package:fluent/data/repository/progress_repository.dart';
import 'package:fluent/data/services/certificate_service.dart';
import 'package:fluent/data/repository/certificate_repository.dart';
import 'package:fluent/data/services/contact_us_service.dart';
import 'package:fluent/data/repository/contact_us_repository.dart';

import 'package:flutter_stripe/flutter_stripe.dart';

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
import 'package:fluent/data/services/teacher_stats_service.dart';
import 'package:fluent/data/repository/teacher_stats_repository.dart';
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
import 'package:fluent/helper/auth_session.dart';
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
import 'package:fluent/data/services/podcast_service.dart';
import 'package:fluent/data/repository/podcast_repository.dart';
import 'package:fluent/data/services/payment_service.dart';
import 'package:fluent/data/repository/payment_repository.dart';

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

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  Stripe.publishableKey = stripePublishableKey;
  await Stripe.instance.applySettings();

  await setupDio();

  // Strict session check (token + is_logged_in). Never trust flag alone.
  final bool isUserLoggedIn = await AuthSession.isLoggedIn();
  final String? userRole = await AuthSession.role();

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

  final teacherStatsService = TeacherStatsService(dioInstance);
  final teacherStatsRepository = TeacherStatsRepository(teacherStatsService);

  final notificationService = NotificationService(dioInstance);
  final notificationRepository = NotificationRepository(notificationService);

  final podcastService = PodcastService(dioInstance);
  final podcastRepository = PodcastRepository(podcastService);

  final chatService = ChatService(dioInstance);
  final chatRepository = ChatRepository(chatService);

  final paymentService = PaymentService(dioInstance);
  final paymentRepository = PaymentRepository(paymentService);

  final progressService = ProgressService(dioInstance);
  final progressRepository = ProgressRepository(progressService);

  final certificateService = CertificateService(dioInstance);
  final certificateRepository = CertificateRepository(certificateService);

  final contactUsService = ContactUsService(dioInstance);
  final contactUsRepository = ContactUsRepository(contactUsService);

  // Logged OUT → always login (never auto-enter app content).
  // Logged IN  → teacher home / student placement-or-home — never login UI.
  String initialRoute = loginRoute;
  if (isUserLoggedIn) {
    if (userRole == 'teacher') {
      initialRoute = teacherHomeRoute;
    } else {
      // student (default if role missing but session valid)
      final placed =
          await StudentEntryNavigator.hasCompletedPlacementStandalone(
            levelRepository,
          );
      initialRoute = placed ? studentHomeRoute : placementTestDialogRoute;
      print('🔍 [main] student placed=$placed → $initialRoute');
    }
  } else {
    print('🔍 [main] no session → loginRoute');
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

      podcastRepository: podcastRepository,
      paymentRepository: paymentRepository,
      chatRepository: chatRepository,
      progressRepository: progressRepository,
      certificateRepository: certificateRepository,
      contactUsRepository: contactUsRepository,
      teacherStatsRepository: teacherStatsRepository,

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

  final PodcastRepository podcastRepository;
  final PaymentRepository paymentRepository;
  final ChatRepository chatRepository;
  final ProgressRepository progressRepository;
  final CertificateRepository certificateRepository;
  final ContactUsRepository contactUsRepository;
  final TeacherStatsRepository teacherStatsRepository;
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
    required this.chatRepository,
    required this.podcastRepository,
    required this.paymentRepository,
    required this.progressRepository,
    required this.certificateRepository,
    required this.contactUsRepository,
    required this.teacherStatsRepository,
  }) {
    appRouter = AppRouter(authRepository);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
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
      _refreshNotifications();
      _ensureFcmRegistered();
    }
  }

  Future<void> _onAppReady() async {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;

    NotificationBootstrap.listenTokenRefresh();

    if (widget.isUserLoggedIn) {
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

  void _setupForegroundMessaging() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('📩 [FG] ${message.notification?.title}');

      await LocalNotificationsService.instance.showFromFirebase(message);

      _refreshNotifications();
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📩 [Opened] ${message.messageId}');
      _refreshNotifications();
      _openFromMessage(message);
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshNotifications();
        _openFromMessage(message);
      });
    });
  }

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

            RepositoryProvider<PodcastRepository>.value(
              value: widget.podcastRepository,
            ),
            RepositoryProvider<PaymentRepository>.value(
              value: widget.paymentRepository,
            ),
            RepositoryProvider<ChatRepository>.value(
              value: widget.chatRepository,
            ),
            RepositoryProvider<ProgressRepository>.value(
              value: widget.progressRepository,
            ),
            RepositoryProvider<CertificateRepository>.value(
              value: widget.certificateRepository,
            ),
            RepositoryProvider<ContactUsRepository>.value(
              value: widget.contactUsRepository,
            ),
            RepositoryProvider<TeacherStatsRepository>.value(
              value: widget.teacherStatsRepository,
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
              navigatorObservers: [routeObserver],
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
