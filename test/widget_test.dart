// // test/widget_test.dart
// import 'package:fluent/data/network/dio_client.dart';
// import 'package:fluent/data/repository/auth_repository.dart';
// import 'package:fluent/data/services/auth_service.dart';
// import 'package:fluent/main.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';

// void main() {
//   // ✅ Setup قبل كل الاختبارات
//   setUpAll(() async {
//     // تهيئة Dio للاختبار
//     await setupDio();
//   });

//   group('FluentApp Widget Tests', () {
//     testWidgets('App should start without crashing', (
//       WidgetTester tester,
//     ) async {
//       // ✅ إنشاء dependencies
//       final authService = AuthService(dio);
//       final authRepository = AuthRepository(authService);

//       // ✅ بناء التطبيق
//       await tester.pumpWidget(
//         MyApp(authRepository: authRepository, initialRoute: '/'),
//       );

//       // ✅ التحقق من أن التطبيق بدأ
//       await tester.pump();

//       // ✅ التحقق من وجود MaterialApp
//       expect(find.byType(MaterialApp), findsOneWidget);
//     });

//     testWidgets('App should show onboarding screen initially', (
//       WidgetTester tester,
//     ) async {
//       final authService = AuthService(dio);
//       final authRepository = AuthRepository(authService);

//       await tester.pumpWidget(
//         MyApp(authRepository: authRepository, initialRoute: '/'),
//       );

//       await tester.pump();

//       // ✅ التحقق من أن التطبيق بدأ (بدون crash)
//       expect(find.byType(MaterialApp), findsOneWidget);
//     });
//   });

//   group('AuthRepository Unit Tests', () {
//     test('AuthRepository should be created successfully', () {
//       final authService = AuthService(dio);
//       final authRepository = AuthRepository(authService);

//       expect(authRepository, isNotNull);
//       expect(authRepository.authService, isNotNull);
//     });
//   });
// }
