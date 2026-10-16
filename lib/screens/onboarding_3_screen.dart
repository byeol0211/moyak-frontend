import 'package:flutter/material.dart';

import 'onboarding_2_screen.dart';

class Onboarding3Screen extends StatelessWidget {
  const Onboarding3Screen({this.onSkip, this.onNext, super.key});

  final VoidCallback? onSkip;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) => OnboardingPage(
    title: '약사와 1:1 화상 상담',
    subtitle: '전자구매허가서를 비대면으로 발급받고 필요한 의약품을 안전하게 구매하세요.',
    previewAsset: 'assets/figma/onboarding_video_preview.png',
    activePage: 3,
    buttonLabel: '다음',
    onSkip: onSkip,
    onNext: onNext,
  );
}
