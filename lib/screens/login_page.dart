import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../data/app_session.dart';
import '../widgets/feature_notice.dart';

const _background = Color(0xFFF5F5F3);
const _brandYellow = Color(0xFFFFD54F);
const _darkBrown = Color(0xFF3E2723);
const _labelBrown = Color(0xFF7D6D6A);
const _hintBrown = Color(0xFFBCAAA4);
const _fieldBorder = Color(0xFFEFEBE9);

class LoginPage extends StatefulWidget {
  const LoginPage({
    required this.onLogin,
    required this.onSignup,
    this.onFindAccount,
    super.key,
  });

  final VoidCallback onLogin;
  final VoidCallback onSignup;
  final VoidCallback? onFindAccount;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _enter({required bool preview, bool guest = false}) async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    if (!preview &&
        !guest &&
        (_username.text.trim().isEmpty || _password.text.isEmpty)) {
      setState(() => _error = '아이디와 비밀번호를 입력해주세요.');
      return;
    }
    // There is no authentication API yet. Never pretend credentials were verified.
    if (!preview && !guest) {
      showFeatureNotice(context, '로그인은 준비 중이에요. 아래 화면 미리보기로 앱을 둘러보세요.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AppSession.instance.initialize();
      if (!mounted) return;
      AppConfig.preview.value = preview;
      widget.onLogin();
    } catch (_) {
      if (mounted) setState(() => _error = '앱 정보를 저장하지 못했어요. 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _background,
    body: SafeArea(
      child: Column(
        children: [
          const _StatusBar(),
          const _LoginHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(
                    height: 43,
                    child: Center(
                      child: Text(
                        'MOYAK',
                        style: TextStyle(
                          color: _brandYellow,
                          fontSize: 68,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  LoginTextField(
                    controller: _username,
                    label: '아이디',
                    hint: '아이디를 입력해주세요',
                  ),
                  const SizedBox(height: 12),
                  LoginTextField(
                    controller: _password,
                    label: '비밀번호',
                    hint: '비밀번호를 입력해주세요',
                    obscureText: true,
                  ),
                  const SizedBox(height: 32),
                  if (_error != null) ...[
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                  ],
                  LoginPrimaryButton(
                    label: '로그인',
                    enabled: !_busy,
                    onPressed: () => _enter(preview: false),
                  ),
                  TextButton(
                    onPressed: _busy ? null : () => _enter(preview: true),
                    child: Text(_busy ? '준비 중...' : '회원가입 없이 화면 미리보기'),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => _enter(preview: false, guest: true),
                    child: const Text('게스트로 계속하기'),
                  ),
                  const SizedBox(height: 24),
                  _AccountLinks(
                    onSignup: widget.onSignup,
                    onFindAccount:
                        widget.onFindAccount ??
                        () => showFeatureNotice(context),
                  ),
                  const SizedBox(height: 32),
                  const SocialLoginDivider(),
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SocialLoginButton(
                        backgroundColor: Color(0xFFFEE500),
                        icon: Icons.chat_bubble_outline,
                        iconColor: _darkBrown,
                      ),
                      SizedBox(width: 20),
                      SocialLoginButton(
                        backgroundColor: Color(0xFF03C75A),
                        label: 'N',
                      ),
                      SizedBox(width: 20),
                      SocialLoginButton(
                        backgroundColor: Colors.white,
                        icon: Icons.g_mobiledata,
                        iconColor: Color(0xFF4285F4),
                        outlined: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const _HomeIndicator(),
        ],
      ),
    ),
  );
}

class LoginTextField extends StatefulWidget {
  const LoginTextField({
    required this.label,
    required this.hint,
    this.obscureText = false,
    this.controller,
    super.key,
  });

  final String label;
  final String hint;
  final bool obscureText;
  final TextEditingController? controller;

  @override
  State<LoginTextField> createState() => _LoginTextFieldState();
}

class _LoginTextFieldState extends State<LoginTextField> {
  bool _visible = false;
  String get label => widget.label;
  String get hint => widget.hint;
  bool get obscureText => widget.obscureText && !_visible;
  TextEditingController? get controller => widget.controller;

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
      SizedBox(
        height: 52,
        child: TextField(
          controller: controller,
          autocorrect: false,
          enableSuggestions: !obscureText,
          obscureText: obscureText,
          style: const TextStyle(color: _darkBrown, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _hintBrown, fontSize: 15),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            suffixIcon: widget.obscureText
                ? IconButton(
                    tooltip: _visible ? '비밀번호 숨기기' : '비밀번호 보기',
                    onPressed: () => setState(() => _visible = !_visible),
                    icon: Icon(
                      _visible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                  )
                : null,
            suffixIconColor: _hintBrown,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _fieldBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _fieldBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _brandYellow, width: 1.5),
            ),
          ),
        ),
      ),
    ],
  );
}

class LoginPrimaryButton extends StatelessWidget {
  const LoginPrimaryButton({
    required this.label,
    required this.onPressed,
    this.enabled = true,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 56,
    child: FilledButton(
      onPressed: enabled ? onPressed : null,
      style: FilledButton.styleFrom(
        backgroundColor: _brandYellow,
        foregroundColor: Colors.white,
        disabledBackgroundColor: _fieldBorder,
        disabledForegroundColor: _hintBrown,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      child: Text(label),
    ),
  );
}

class SocialLoginDivider extends StatelessWidget {
  const SocialLoginDivider({super.key});

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Expanded(child: Divider(color: _fieldBorder)),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          'SNS 간편 로그인',
          style: TextStyle(
            color: _hintBrown,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      Expanded(child: Divider(color: _fieldBorder)),
    ],
  );
}

class SocialLoginButton extends StatelessWidget {
  const SocialLoginButton({
    required this.backgroundColor,
    this.label,
    this.icon,
    this.iconColor = Colors.white,
    this.outlined = false,
    super.key,
  });

  final Color backgroundColor;
  final String? label;
  final IconData? icon;
  final Color iconColor;
  final bool outlined;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => showFeatureNotice(context, '소셜 로그인은 준비 중이에요.'),
    customBorder: const CircleBorder(),
    child: Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: outlined ? Border.all(color: _fieldBorder) : null,
      ),
      child: Center(
        child: label == null
            ? Icon(icon, color: iconColor, size: 24)
            : Text(
                label!,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
      ),
    ),
  );
}

class _StatusBar extends StatelessWidget {
  const _StatusBar();
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 56,
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          SizedBox(width: 40),
          Expanded(
            child: Text(
              '로그인',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _darkBrown,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: 40),
        ],
      ),
    ),
  );
}

class _AccountLinks extends StatelessWidget {
  const _AccountLinks({required this.onSignup, this.onFindAccount});

  final VoidCallback onSignup;
  final VoidCallback? onFindAccount;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      TextButton(
        onPressed: onSignup,
        style: TextButton.styleFrom(foregroundColor: _labelBrown),
        child: const Text('회원가입', style: TextStyle(fontSize: 14)),
      ),
      const SizedBox(
        height: 12,
        child: VerticalDivider(width: 1, color: _hintBrown),
      ),
      TextButton(
        onPressed: onFindAccount ?? () {},
        style: TextButton.styleFrom(foregroundColor: _labelBrown),
        child: const Text('ID·PW 찾기', style: TextStyle(fontSize: 14)),
      ),
    ],
  );
}

class _HomeIndicator extends StatelessWidget {
  const _HomeIndicator();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 33,
    child: Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: 134,
        height: 5,
        margin: const EdgeInsets.only(top: 20),
        decoration: BoxDecoration(
          color: _darkBrown.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(100),
        ),
      ),
    ),
  );
}
