import 'package:flutter/material.dart';

import 'onboarding_1_screen.dart';
import 'onboarding_2_screen.dart';
import 'onboarding_3_screen.dart';
import 'onboarding_4_screen.dart';
import '../data/auth_api.dart';
import 'signup_form.dart';

class SignupFlow extends StatelessWidget {
  const SignupFlow({required this.onComplete, this.auth, super.key});
  final AuthApi? auth;
  final VoidCallback onComplete;
  @override
  Widget build(BuildContext context) =>
      SignupForm(auth: auth, onComplete: onComplete);
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
