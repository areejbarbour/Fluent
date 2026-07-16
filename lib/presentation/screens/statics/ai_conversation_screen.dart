// 📁 lib/presentation/screens/ai_conversation/ai_conversation_screen.dart

import 'package:fluent/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AIConversationScreen extends StatelessWidget {
  const AIConversationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          "AI Conversation",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.headset_rounded, size: 80.sp, color: AppColors.yellow),
            SizedBox(height: 20.h),
            Text(
              "AI Chat Coming Soon 🤖",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}