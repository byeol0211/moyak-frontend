import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../utils/input_validation.dart';

const _background = Color(0xFFF5F5F3);
const _brandYellow = Color(0xFFFFD54F);
const _darkBrown = Color(0xFF3E2723);
const _labelBrown = Color(0xFF7D6D6A);
const _hintBrown = Color(0xFFBCAAA4);
const _fieldBorder = Color(0xFFEFEBE9);
const _successGreen = Color(0xFF2E7D32);
const _errorRed = Color(0xFFC62828);

class SignupStep2Screen extends StatefulWidget {
  const SignupStep2Screen({
    this.onBack,
    this.onNext,
    this.onSubmit,
    this.busy = false,
    super.key,
  });

  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final ValueChanged<String>? onSubmit;
  final bool busy;

  @override
  State<SignupStep2Screen> createState() => _SignupStep2ScreenState();
}

class _SignupStep2ScreenState extends State<SignupStep2Screen> {
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _passwordVisible = false;
  bool _confirmationVisible = false;

  bool get _passwordValid {
    final password = _passwordController.text;
    return InputValidation.password(password);
  }

  bool get _passwordsMatch =>
      _confirmationController.text.isNotEmpty &&
      _passwordController.text == _confirmationController.text;

  bool get _canContinue => _passwordValid && _passwordsMatch;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

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
                    _PasswordInputGroup(
                      label: '비밀번호',
                      controller: _passwordController,
                      isVisible: _passwordVisible,
                      onVisibilityChanged: (value) {
                        setState(() => _passwordVisible = value);
                      },
                      onChanged: (_) => setState(() {}),
                      helper: _passwordHelper,
                    ),
                    const SizedBox(height: 24),
                    _PasswordInputGroup(
                      label: '비밀번호 확인',
                      controller: _confirmationController,
                      isVisible: _confirmationVisible,
                      onVisibilityChanged: (value) {
                        setState(() => _confirmationVisible = value);
                      },
                      onChanged: (_) => setState(() {}),
                      helper: _confirmationHelper,
                    ),
                  ],
                ),
              ),
            ),
            _SignupBottomAction(
              enabled: _canContinue && !widget.busy,
              onPressed: () {
                if (widget.busy) return;
                if (widget.onSubmit != null) {
                  widget.onSubmit!(_passwordController.text);
                } else {
                  widget.onNext?.call();
                }
              },
            ),
          ],
        ),
      ),
    ),
  );

  Widget get _passwordHelper {
    final password = _passwordController.text;
    if (password.isEmpty) return const SizedBox(height: 14);
    if (_passwordValid) {
      return const _ValidationMessage(
        text: '✓ 영문, 숫자, 특수문자 조합 8자 이상 충족',
        color: _successGreen,
      );
    }
    return const _ValidationMessage(
      text: '영문, 숫자, 특수문자 조합 8자 이상 입력해주세요.',
      color: _errorRed,
    );
  }

  Widget get _confirmationHelper {
    final confirmation = _confirmationController.text;
    if (confirmation.isEmpty) return const SizedBox(height: 14);
    if (_passwordsMatch) {
      return const _ValidationMessage(
        text: '✓ 비밀번호가 일치합니다.',
        color: _successGreen,
      );
    }
    return const _ValidationMessage(
      text: '✗ 비밀번호가 일치하지 않습니다.',
      color: _errorRed,
    );
  }
}

class _PasswordInputGroup extends StatelessWidget {
  const _PasswordInputGroup({
    required this.label,
    required this.controller,
    required this.isVisible,
    required this.onVisibilityChanged,
    required this.onChanged,
    required this.helper,
  });

  final String label;
  final TextEditingController controller;
  final bool isVisible;
  final ValueChanged<bool> onVisibilityChanged;
  final ValueChanged<String> onChanged;
  final Widget helper;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: _labelBrown,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 8),
      Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _fieldBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                obscureText: !isVisible,
                onChanged: onChanged,
                autofillHints: const [AutofillHints.newPassword],
                style: const TextStyle(color: _darkBrown, fontSize: 15),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
            Semantics(
              button: true,
              label: isVisible ? '비밀번호 숨기기' : '비밀번호 표시',
              child: GestureDetector(
                onTap: () => onVisibilityChanged(!isVisible),
                child: SvgPicture.asset(
                  isVisible
                      ? 'assets/figma/password_eye_off.svg'
                      : 'assets/figma/password_eye.svg',
                  width: 20,
                  height: 20,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      helper,
    ],
  );
}

class _ValidationMessage extends StatelessWidget {
  const _ValidationMessage({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: TextStyle(color: color, fontSize: 12, height: 1));
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
          const Expanded(
            child: Text(
              '회원가입',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _darkBrown,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 40),
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
              '비밀번호 설정',
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
  const _SignupBottomAction({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: enabled ? onPressed : null,
            style: FilledButton.styleFrom(
              backgroundColor: _brandYellow,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _fieldBorder,
              disabledForegroundColor: _hintBrown,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('다음'),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: 134,
          height: 5,
          decoration: BoxDecoration(
            color: _darkBrown.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(100),
          ),
        ),
        const SizedBox(height: 8),
      ],
    ),
  );
}
