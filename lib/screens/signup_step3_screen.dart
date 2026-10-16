import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _background = Color(0xFFF5F5F3);
const _brandYellow = Color(0xFFFFD54F);
const _completeYellow = Color(0xFFFFD970);
const _darkBrown = Color(0xFF3E2723);
const _labelBrown = Color(0xFF7D6D6A);
const _fieldBorder = Color(0xFFEFEBE9);
const _iconBackground = Color(0xFFFFFDE7);

enum VerificationMethod { email, simple }

class SignupStep3Screen extends StatefulWidget {
  const SignupStep3Screen({
    this.initialSelection = VerificationMethod.email,
    this.onBack,
    this.onComplete,
    super.key,
  });

  final VerificationMethod initialSelection;
  final VoidCallback? onBack;
  final ValueChanged<VerificationMethod>? onComplete;

  @override
  State<SignupStep3Screen> createState() => _SignupStep3ScreenState();
}

class _SignupStep3ScreenState extends State<SignupStep3Screen> {
  late VerificationMethod _selectedMethod = widget.initialSelection;

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
        child: Column(
          children: [
            const _SignupStatusBar(),
            _SignupHeader(onBack: widget.onBack),
            const _SignupProgress(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '원활한 약품 결제를 위해 인증 방식을 선택해주세요',
                      style: TextStyle(
                        color: _labelBrown,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 20),
                    _VerificationCard(
                      title: '이메일 인증',
                      description: '등록된 이메일 계정으로 인증 메일을 보냅니다.',
                      iconAsset: 'assets/figma/email_verification.svg',
                      selected: _selectedMethod == VerificationMethod.email,
                      onTap: () => setState(
                        () => _selectedMethod = VerificationMethod.email,
                      ),
                    ),
                    SizedBox(height: 12),
                    _VerificationCard(
                      title: '간편인증',
                      description: '카카오, 토스 등 민간인증서로 빠르게 인증합니다.',
                      iconAsset: 'assets/figma/shield_verification.svg',
                      selected: _selectedMethod == VerificationMethod.simple,
                      onTap: () => setState(
                        () => _selectedMethod = VerificationMethod.simple,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _SignupBottomAction(
              onPressed: () => widget.onComplete?.call(_selectedMethod),
            ),
          ],
        ),
      ),
    ),
  );
}

class _VerificationCard extends StatelessWidget {
  const _VerificationCard({
    required this.title,
    required this.description,
    required this.iconAsset,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final String iconAsset;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: selected ? _brandYellow : _fieldBorder,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              offset: Offset(0, 4),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected ? _iconBackground : _background,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(iconAsset, width: 24, height: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _darkBrown,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: _labelBrown,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: selected ? _brandYellow : _fieldBorder,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                'assets/figma/check_verification.svg',
                width: 14,
                height: 14,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SignupStatusBar extends StatelessWidget {
  const _SignupStatusBar();
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _SignupHeader extends StatelessWidget {
  const _SignupHeader({required this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 56,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
              icon: SvgPicture.asset(
                'assets/figma/chevron_left.svg',
                width: 24,
                height: 24,
              ),
            ),
          ),
          const Spacer(),
          const Text(
            '회원가입',
            style: TextStyle(
              color: _darkBrown,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class _SignupProgress extends StatelessWidget {
  const _SignupProgress();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
    child: Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '본인 인증',
              style: TextStyle(
                color: _brandYellow,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '3 / 3',
              style: TextStyle(
                color: _labelBrown,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: const SizedBox(
            height: 6,
            child: LinearProgressIndicator(
              value: 1,
              backgroundColor: _fieldBorder,
              color: _brandYellow,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SignupBottomAction extends StatelessWidget {
  const _SignupBottomAction({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 56,
          width: double.infinity,
          child: FilledButton(
            onPressed: onPressed ?? () {},
            style: FilledButton.styleFrom(
              backgroundColor: _completeYellow,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('완료'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 33,
          child: Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 8),
            child: Center(
              child: Container(
                width: 134,
                height: 5,
                decoration: BoxDecoration(
                  color: _darkBrown.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
