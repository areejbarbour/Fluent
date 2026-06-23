import 'package:flutter/material.dart';

class OnboardingModel {
  final String image;
  final String title;
  final String subtitle;
  final String buttonText;
  final bool isFilledButton;

  OnboardingModel({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    this.isFilledButton = true,
  });
}