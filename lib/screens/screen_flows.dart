import 'package:flutter/material.dart';

import 'onboarding_1_screen.dart';
import 'onboarding_2_screen.dart';
import 'onboarding_3_screen.dart';
import 'onboarding_4_screen.dart';
import 'signup_step1_screen.dart';
import 'signup_step2_screen.dart';
import 'signup_step3_screen.dart';

class SignupFlow extends StatefulWidget {
  const SignupFlow({required this.onComplete, super.key});

  final VoidCallback onComplete;

  @override
  State<SignupFlow> createState() => _SignupFlowState();
}

class _SignupFlowState extends State<SignupFlow> {
  int _step = 0;

  void _goBack() {
    if (_step == 0) {
      Navigator.of(context).maybePop();
    } else {
      setState(() => _step--);
    }
  }

  @override
  Widget build(BuildContext context) => IndexedStack(
    index: _step,
    children: [
      SignupStep1Screen(
        onBack: _goBack,
        onCheckAvailability: (_) async => true,
        onNext: (_) => setState(() => _step = 1),
      ),
      SignupStep2Screen(
        onBack: _goBack,
        onNext: () => setState(() => _step = 2),
      ),
      SignupStep3Screen(onBack: _goBack, onComplete: (_) => widget.onComplete()),
    ],
  );
}

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({required this.onComplete, super.key});

  final VoidCallback onComplete;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_page == 3) {
      widget.onComplete();
      return;
    }
    setState(() => _page++);
    _pageController.animateToPage(
      _page,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) => PageView(
    controller: _pageController,
    physics: const NeverScrollableScrollPhysics(),
    children: [
      Onboarding1Screen(onSkip: widget.onComplete, onStart: _nextPage),
      Onboarding2Screen(onSkip: widget.onComplete, onNext: _nextPage),
      Onboarding3Screen(onSkip: widget.onComplete, onNext: _nextPage),
      Onboarding4Screen(onSkip: widget.onComplete, onStart: widget.onComplete),
    ],
  );
}
