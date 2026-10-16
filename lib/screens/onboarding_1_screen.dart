import 'package:flutter/material.dart';

import 'onboarding_2_screen.dart';

class Onboarding1Screen extends StatelessWidget {
  const Onboarding1Screen({this.onSkip, this.onStart, super.key});

  final VoidCallback? onSkip;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) => OnboardingPage(
    title: '스마트 자판기와 연동하세요',
    subtitle: '일반 및 인증 약품을 간편하게 구매하세요',
    previewAsset: 'assets/figma/onboarding_vending_preview.png',
    activePage: 1,
    buttonLabel: '시작하기',
    onSkip: onSkip,
    onNext: onStart,
  );
}
