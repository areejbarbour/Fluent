import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app_router.dart';
import 'constants/strings.dart';

void main() {
  runApp(const FluentApp());
}

class FluentApp extends StatelessWidget {
  const FluentApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appRouter = AppRouter();
    final bool isLoggedIn = false;

    return ScreenUtilInit(
      designSize: const Size(
        360,
        690,
      ), // غيّر هذا المقاس إذا كان تصميمك في Figma على مقاسات أخرى
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Fluent',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: Colors.transparent,
          ),
          initialRoute: isLoggedIn ? homeRoute : onboardingRoute,
          onGenerateRoute: appRouter.generateRoute,
        );
      },
    );
  }
}
