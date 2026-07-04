import 'package:fluent/cubit/auth/forgot_password/forgot_password_cubit.dart';
import 'package:fluent/cubit/auth/reset_password/reset_password_cubit.dart';
import 'package:fluent/cubit/auth/verify_otp/verify_otp_cubit.dart';
import 'package:fluent/presentation/screens/Streak/StreakScreen.dart';
import 'package:fluent/presentation/screens/auth/OtpVerificationScreen.dart';
import 'package:fluent/presentation/screens/auth/forget_password_screen.dart';
import 'package:fluent/presentation/screens/auth/set_new_password_screen.dart';
import 'package:fluent/presentation/screens/home/student_home_screen.dart';
import 'package:fluent/presentation/screens/home/teacher_home_screen.dart';
import 'package:fluent/presentation/screens/placement/placement_test_screen.dart';
import 'package:fluent/presentation/screens/placementTestDialog.dart';
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

class AppRouter {
  final AuthRepository authRepository;

  AppRouter(this.authRepository);

  Route<dynamic>? generateRoute(RouteSettings settings) {
    print("🧭 [AppRouter] Generating route: ${settings.name}");

    switch (settings.name) {
      case onboardingRoute:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());

      case loginRoute:
        final email = settings.arguments as String?; // ✅ استقبال الإيميل
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => LoginCubit(authRepository),
            child: LoginScreen(email: email), // ✅ تمرير الإيميل
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
            child:
                const SetNewPasswordScreen(), // ✅ إزالة email من الـ constructor
          ),
          settings: RouteSettings(
            arguments: email,
          ), // ✅ تمرير email عبر settings
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

      // ✅ Route للطالب
      case studentHomeRoute:
        return MaterialPageRoute(builder: (_) => const StudentHomeScreen());

      // ✅ Route للمعلم
      case teacherHomeRoute:
        return MaterialPageRoute(builder: (_) => const TeacherHomeScreen());

      case levelCoursesRoute:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => LevelCoursesScreen(
            userName: args['userName'] as String? ?? "Rasha",
            xp: args['xp'] as int? ?? 12540,
            streakDays: args['streakDays'] as int? ?? 15,
            level: args['level'] as int? ?? 8,
            levelProgress: args['levelProgress'] as double? ?? 0.78,
            levelTitle: args['levelTitle'] as String? ?? "Level 8",
            levelSubtitle:
                args['levelSubtitle'] as String? ?? "Grammar Mastery",
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
