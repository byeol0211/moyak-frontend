import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../data/app_session.dart';
import '../data/auth_api.dart';
import '../utils/input_validation.dart';

class SignupForm extends StatefulWidget {
  const SignupForm({required this.onComplete, this.auth, super.key});
  final VoidCallback onComplete;
  final AuthApi? auth;
  @override
  State<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  late final _auth = widget.auth ?? AuthApi();
  bool _busy = false;
  bool _checking = false;
  String? _checked;
  String? _error;
  int _checkGeneration = 0;

  Future<void> _check() async {
    final username = _username.text.trim();
    if (!InputValidation.username(username)) {
      setState(() => _error = '아이디는 영문, 숫자, 밑줄로 4~20자 입력해주세요.');
      return;
    }
    final generation = ++_checkGeneration;
    setState(() {
      _checking = true;
      _checked = null;
      _error = null;
    });
    try {
      final available =
          AppConfig.preview.value || await _auth.available(username);
      if (!mounted ||
          generation != _checkGeneration ||
          username != _username.text.trim()) {
        return;
      }
      setState(() {
        _checked = available ? username : null;
        _error = available ? null : '이미 사용 중인 아이디입니다.';
      });
    } catch (error) {
      if (mounted && generation == _checkGeneration) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted && generation == _checkGeneration) {
        setState(() => _checking = false);
      }
    }
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    if (_checked != _username.text.trim()) {
      setState(() => _error = '아이디 중복확인을 해주세요.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (AppConfig.preview.value) {
        await AppSession.instance.initialize();
        AppSession.instance.userName = _name.text.trim();
        AppSession.instance.username = _username.text.trim();
      } else {
        await _auth.signup(
          _username.text,
          _password.text,
          name: _name.text.trim(),
        );
      }
      if (mounted) widget.onComplete();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _decoration(String label, String hint) => InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFEFEBE9)),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      backgroundColor: const Color(0xFFF5F5F3),
      appBar: AppBar(
        title: const Text('회원가입'),
        backgroundColor: const Color(0xFFF5F5F3),
        foregroundColor: const Color(0xFF3E2723),
      ),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                '모약에 오신 것을 환영해요',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3E2723),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '이름과 로그인 정보를 입력해주세요.',
                style: TextStyle(color: Color(0xFF7D6D6A)),
              ),
              const SizedBox(height: 24),
              TextFormField(
                key: const Key('signup-name'),
                controller: _name,
                enabled: !_busy,
                maxLength: 40,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                decoration: _decoration('이름', '예: 홍길동'),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? '이름을 입력해주세요.'
                    : (value!.trim().runes.length > 40
                          ? '이름은 40자 이내로 입력해주세요.'
                          : null),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('signup-username'),
                controller: _username,
                enabled: !_busy,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newUsername],
                decoration: _decoration('아이디', '영문·숫자·밑줄 4~20자'),
                validator: (value) => InputValidation.username(value ?? '')
                    ? null
                    : '아이디는 영문, 숫자, 밑줄로 4~20자 입력해주세요.',
                onChanged: (_) => setState(() {
                  _checked = null;
                  _checking = false;
                  _checkGeneration++;
                }),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _busy || _checking ? null : _check,
                  child: Text(
                    _checking
                        ? '확인 중...'
                        : _checked == null
                        ? '중복확인'
                        : '사용 가능한 아이디입니다.',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('signup-password'),
                controller: _password,
                enabled: !_busy,
                obscureText: true,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                decoration: _decoration('비밀번호', '영문·숫자·특수문자 포함 8자 이상'),
                validator: (value) => InputValidation.password(value ?? '')
                    ? null
                    : '영문, 숫자, 특수문자를 포함해 8자 이상 입력해주세요.',
              ),
              const SizedBox(height: 20),
              TextFormField(
                key: const Key('signup-confirm'),
                controller: _confirm,
                enabled: !_busy,
                obscureText: true,
                textInputAction: TextInputAction.done,
                decoration: _decoration('비밀번호 확인', '비밀번호를 다시 입력해주세요'),
                validator: (value) =>
                    value == _password.text && (value ?? '').isNotEmpty
                    ? null
                    : '비밀번호가 일치하지 않습니다.',
                onFieldSubmitted: (_) => _submit(),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFFC62828)),
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: _busy || _checking ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD54F),
                    foregroundColor: const Color(0xFF3E2723),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(_busy ? '가입 중...' : '회원가입'),
                ),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                        AppConfig.preview.value = !AppConfig.preview.value;
                        _checked = null;
                        _checking = false;
                        _checkGeneration++;
                      }),
                child: Text(
                  AppConfig.preview.value
                      ? '가입 화면 미리보기 중 · 종료'
                      : '가입 화면 미리보기 시작',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  @override
  void dispose() {
    for (final c in [_name, _username, _password, _confirm]) {
      c.dispose();
    }
    if (widget.auth == null) _auth.close();
    super.dispose();
  }
}
