import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'login_page.dart';

const _background = Color(0xFFFFFDE7);
const _darkBrown = Color(0xFF3E2723);
const _labelBrown = Color(0xFF7D6D6A);
const _brandYellow = Color(0xFFFFD54F);
const _inactiveDot = Color(0xFFEFEBE9);

class Onboarding2Screen extends StatelessWidget {
  const Onboarding2Screen({this.onSkip, this.onNext, super.key});

  final VoidCallback? onSkip;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) => OnboardingPage(
    title: 'AI 챗봇 모약이에게 물어보세요',
    subtitle: '약품 정보와 증상 상담을 쉽고 편리하게 받을 수 있어요.',
    previewAsset: 'assets/figma/onboarding_chat_preview.png',
    activePage: 2,
    buttonLabel: '다음',
    onSkip: onSkip,
    onNext: onNext,
  );
}

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.previewAsset,
    required this.activePage,
    required this.buttonLabel,
    this.onSkip,
    this.onNext,
    super.key,
  });

  final String title;
  final String subtitle;
  final String previewAsset;
  final int activePage;
  final String buttonLabel;
  final VoidCallback? onSkip;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarColor: _background,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: _background,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
    child: Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final previewWidth = (constraints.maxWidth - 62)
                .clamp(0.0, 339.0)
                .toDouble();

            return Stack(
              fit: StackFit.expand,
              children: [
                Column(
                  children: [
                    const _OnboardingStatusBar(),
                    _SkipAction(onPressed: onSkip),
                    const SizedBox(height: 3),
                    _OnboardingText(title: title, subtitle: subtitle),
                    const SizedBox(height: 33),
                    Expanded(
                      child: ClipRect(
                        child: OverflowBox(
                          alignment: Alignment.topCenter,
                          minHeight: 0,
                          maxHeight: double.infinity,
                          child: _PhonePreview(
                            width: previewWidth,
                            asset: previewAsset,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _OnboardingBottomControls(
                    onNext: onNext,
                    activePage: activePage,
                    buttonLabel: buttonLabel,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

class _OnboardingStatusBar extends StatelessWidget {
  const _OnboardingStatusBar();
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _SkipAction extends StatelessWidget {
  const _SkipAction({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            backgroundColor: const Color(0x143E2723),
            foregroundColor: _darkBrown,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: const Text('건너뛰기'),
        ),
      ),
    ),
  );
}

class _OnboardingText extends StatelessWidget {
  const _OnboardingText({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
    child: Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _darkBrown,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            height: 1.3,
          ),
        ),
        SizedBox(height: 12),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(color: _labelBrown, fontSize: 15, height: 1.5),
        ),
      ],
    ),
  );
}

class _PhonePreview extends StatelessWidget {
  const _PhonePreview({required this.width, required this.asset});

  final double width;
  final String asset;

  @override
  Widget build(BuildContext context) {
    final height = width * 736 / 339;

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 4),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Image.asset(
              asset,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingBottomControls extends StatelessWidget {
  const _OnboardingBottomControls({
    required this.onNext,
    required this.activePage,
    required this.buttonLabel,
  });

  final VoidCallback? onNext;
  final int activePage;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: _background,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PageIndicator(activePage: activePage),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: LoginPrimaryButton(
              label: buttonLabel,
              onPressed: onNext ?? () {},
            ),
          ),
          const SizedBox(height: 28),
          Container(
            width: 134,
            height: 5,
            decoration: BoxDecoration(
              color: _darkBrown.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.activePage});

  final int activePage;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(4, (index) {
      final dot = _PageDot(active: index + 1 == activePage);
      return index == 0 ? dot : Row(children: [const SizedBox(width: 8), dot]);
    }),
  );
}

class _PageDot extends StatelessWidget {
  const _PageDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) => Container(
    width: active ? 24 : 8,
    height: 8,
    decoration: BoxDecoration(
      color: active ? _brandYellow : _inactiveDot,
      borderRadius: BorderRadius.circular(4),
    ),
  );
}
