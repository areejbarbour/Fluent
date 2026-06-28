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
import 'package:fluent/data/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_router.dart';
import 'constants/strings.dart';

// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDio();

  final prefs = await SharedPreferences.getInstance();
  final bool isUserLoggedIn = prefs.getBool('is_logged_in') ?? false;

  // ✅ قراءة الدور
  final String? userRole = prefs.getString('user_role');

  print("🔍 [main] isUserLoggedIn: $isUserLoggedIn");
  print("🔍 [main] userRole: $userRole");

  final Dio dioInstance = dio;
  final authService = AuthService(dioInstance);
  final authRepository = AuthRepository(authService);

  // ✅ تحديد الـ initialRoute حسب الدور
  String initialRoute = onboardingRoute;

  if (isUserLoggedIn) {
    if (userRole == 'teacher') {
      initialRoute = teacherHomeRoute; // 🎓 صفحة المعلم
    } else {
      initialRoute = studentHomeRoute; // 🎓 صفحة الطالب
    }
  }

  runApp(MyApp(authRepository: authRepository, initialRoute: initialRoute));
}

class MyApp extends StatefulWidget {
  final AuthRepository authRepository;
  final String initialRoute;
  late final AppRouter appRouter;

  MyApp({super.key, required this.authRepository, required this.initialRoute}) {
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

              BlocProvider(create: (_) => GoogleLoginCubit(widget.authRepository)),
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
