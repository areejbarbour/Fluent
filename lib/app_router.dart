import 'dart:async';

import 'package:fluent/presentation/screens/Streak/StreakScreen.dart';
import 'package:fluent/presentation/screens/auth/OtpVerificationScreen.dart';
import 'package:fluent/presentation/screens/placementTestDialog.dart';
import 'package:flutter/material.dart';

import 'constants/strings.dart';
import 'presentation/screens/auth/forget_password_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/auth/set_new_password_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';

class AppRouter {
  Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case onboardingRoute:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());

      case loginRoute:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case registerRoute:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case otpRoute:
        return MaterialPageRoute(builder: (_) => const OtpVerificationScreen());

      case forgotPasswordRoute:
        return MaterialPageRoute(builder: (_) => const ForgetPasswordScreen());

      case resetPasswordRoute:
      case setNewPasswordRoute:
        return MaterialPageRoute(builder: (_) => const SetNewPasswordScreen());

      case streakRoute:
        return MaterialPageRoute(builder: (_) => const StreakScreen());

      case placementTestRoute:
        return MaterialPageRoute(builder: (_) => const PlacementTestDialog());

      case homeRoute:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Page not found'))),
        );
    }
  }
}
