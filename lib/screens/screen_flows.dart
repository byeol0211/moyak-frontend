import 'package:flutter/material.dart';

import 'onboarding_1_screen.dart';
import 'onboarding_2_screen.dart';
import 'onboarding_3_screen.dart';
import 'onboarding_4_screen.dart';
import 'signup_step1_screen.dart';
import 'signup_step2_screen.dart';
import 'signup_step3_screen.dart';
import '../config/app_config.dart';
import '../widgets/feature_notice.dart';
import '../data/app_session.dart';

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
  Widget build(BuildContext context) => PopScope(
    canPop: _step == 0,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _goBack();
    },
    child: Column(
      children: [
        Material(
          child: SafeArea(
            bottom: false,
            child: TextButton(
              onPressed: () => setState(
                () => AppConfig.preview.value = !AppConfig.preview.value,
              ),
              child: Text(
                AppConfig.preview.value ? '가입 화면 미리보기 중 · 종료' : '가입 화면 미리보기 시작',
              ),
            ),
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _step,
            children: [
              SignupStep1Screen(
                onBack: _goBack,
                onCheckAvailability: (_) async {
                  if (!AppConfig.preview.value) {
                    throw StateError('아이디 중복 확인 준비 중');
                  }
                  return true;
                },
                onNext: (_) => setState(() => _step = 1),
              ),
              SignupStep2Screen(
                onBack: _goBack,
                onNext: () => setState(() => _step = 2),
              ),
              SignupStep3Screen(
                onBack: _goBack,
                onComplete: (_) async {
                  if (AppConfig.preview.value) {
                    try {
                      await AppSession.instance.initialize();
                      if (mounted) widget.onComplete();
                    } catch (_) {
                      if (context.mounted) {
                        showFeatureNotice(
                          context,
                          '앱 정보를 저장하지 못했어요. 다시 시도해주세요.',
                        );
                      }
                    }
                  } else {
                    showFeatureNotice(
                      context,
                      '본인인증과 회원가입은 준비 중이에요. 화면 미리보기로 먼저 둘러볼 수 있어요.',
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ],
    ),
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
