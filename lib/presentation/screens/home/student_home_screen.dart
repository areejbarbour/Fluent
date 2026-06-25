import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Dashboard')),
      body: const Center(
        child: Text('Welcome Student! 🎓'),
      ),
    );
  }
}