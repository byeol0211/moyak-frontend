import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'login_page.dart';

const _background = Color(0xFFF5F5F3);
const _brandYellow = Color(0xFFFFD54F);
const _darkBrown = Color(0xFF3E2723);
const _labelBrown = Color(0xFF7D6D6A);
const _hintBrown = Color(0xFFBCAAA4);
const _fieldBorder = Color(0xFFEFEBE9);
const _successGreen = Color(0xFF2E7D32);
const _errorRed = Color(0xFFC62828);

class SignupStep1Screen extends StatefulWidget {
  const SignupStep1Screen({
    this.onBack,
    this.onCheckAvailability,
    this.onNext,
    super.key,
  });

  final VoidCallback? onBack;
  final Future<bool> Function(String username)? onCheckAvailability;
  final ValueChanged<String>? onNext;

  @override
  State<SignupStep1Screen> createState() => _SignupStep1ScreenState();
}

class _SignupStep1ScreenState extends State<SignupStep1Screen> {
  final _usernameController = TextEditingController(text: 'moyak_user12');
  bool? _isAvailable = true;
  bool _isChecking = false;
  String? _availabilityError;

  bool get _canContinue => _usernameController.text.trim().isNotEmpty &&
      _isAvailable == true &&
      !_isChecking;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _checkAvailability() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty ||
        !RegExp(r'^[A-Za-z0-9_]{4,20}$').hasMatch(username)) {
      setState(() {
        _isAvailable = false;
        _availabilityError = '아이디는 영문, 숫자, 밑줄로 4~20자 입력해주세요.';
      });
      return;
    }

    final checkAvailability = widget.onCheckAvailability;
    if (checkAvailability == null) {
      setState(() {
        _isAvailable = false;
        _availabilityError = '아이디 중복 확인 기능이 연결되지 않았습니다.';
      });
      return;
    }

    setState(() {
      _isChecking = true;
      _availabilityError = null;
    });

    try {
      final available = await checkAvailability(username);
      if (!mounted) return;
      setState(() {
        _isAvailable = available;
        _availabilityError = available ? null : '이미 사용 중인 아이디입니다.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isAvailable = false;
        _availabilityError = '아이디 확인 중 오류가 발생했습니다.';
      });
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
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
                    const Text(
                      '사용하실 아이디를 입력해주세요',
                      style: TextStyle(
                        color: _labelBrown,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: TextField(
                              controller: _usernameController,
                              onChanged: (_) => setState(() {
                                _isAvailable = null;
                                _availabilityError = null;
                              }),
                              style: const TextStyle(
                                color: _darkBrown,
                                fontSize: 15,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: _fieldBorder,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: _fieldBorder,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: _brandYellow,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 88,
                          height: 52,
                          child: FilledButton(
                            onPressed: _isChecking ? null : _checkAvailability,
                            style: FilledButton.styleFrom(
                              backgroundColor: _darkBrown,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: _darkBrown,
                              disabledForegroundColor: Colors.white70,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: Text(_isChecking ? '확인 중' : '중복확인'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _AvailabilityMessage(
                      isAvailable: _isAvailable,
                      error: _availabilityError,
                    ),
                  ],
                ),
              ),
            ),
            _SignupBottomAction(
              enabled: _canContinue,
              onPressed: () => widget.onNext?.call(
                _usernameController.text.trim(),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AvailabilityMessage extends StatelessWidget {
  const _AvailabilityMessage({required this.isAvailable, required this.error});

  final bool? isAvailable;
  final String? error;

  @override
  Widget build(BuildContext context) {
    if (isAvailable == true) {
      return const Text(
        '✓ 사용 가능한 아이디입니다.',
        style: TextStyle(color: _successGreen, fontSize: 12, height: 1),
      );
    }
    if (error != null) {
      return Text(
        '✗ $error',
        style: const TextStyle(color: _errorRed, fontSize: 12, height: 1),
      );
    }
    return const SizedBox(
      height: 12,
      child: Text(
        '아이디 중복확인을 해주세요.',
        style: TextStyle(color: _hintBrown, fontSize: 12, height: 1),
      ),
    );
  }
}

class _SignupStatusBar extends StatelessWidget {
  const _SignupStatusBar();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 44,
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '9:41',
            style: TextStyle(
              color: _darkBrown,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          Row(
            children: [
              Icon(Icons.signal_cellular_4_bar, color: _darkBrown, size: 18),
              SizedBox(width: 6),
              Icon(Icons.wifi, color: _darkBrown, size: 18),
              SizedBox(width: 6),
              Icon(Icons.battery_full, color: _darkBrown, size: 20),
            ],
          ),
        ],
      ),
    ),
  );
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
              '아이디 설정',
              style: TextStyle(
                color: _brandYellow,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '1 / 3',
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
              value: 1 / 3,
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
        LoginPrimaryButton(
          label: '다음',
          onPressed: onPressed ?? () {},
          enabled: enabled,
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