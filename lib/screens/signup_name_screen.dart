import 'package:flutter/material.dart';

class SignupNameScreen extends StatefulWidget {
  const SignupNameScreen({
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final ValueChanged<String> onNext;
  final VoidCallback onBack;

  @override
  State<SignupNameScreen> createState() => _SignupNameScreenState();
}

class _SignupNameScreenState extends State<SignupNameScreen> {
  final _name = TextEditingController();
  final _form = GlobalKey<FormState>();

  void _next() {
    if (_form.currentState?.validate() == true) {
      FocusScope.of(context).unfocus();
      widget.onNext(_name.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFFFFCF6),
    child: SafeArea(
      child: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
                tooltip: '이전 단계',
              ),
            ),
            const Text(
              '이름 입력',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3E2723),
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('회원가입'), Text('2 / 3')],
            ),
            const SizedBox(height: 8),
            const LinearProgressIndicator(
              value: 2 / 3,
              color: Color(0xFFFFC928),
            ),
            const SizedBox(height: 32),
            const Text(
              '사용하실 이름을 알려주세요.',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text('입력한 이름은 마이페이지에 표시됩니다. 로그인 아이디와는 별도로 저장돼요.'),
            const SizedBox(height: 24),
            TextFormField(
              controller: _name,
              maxLength: 40,
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              decoration: const InputDecoration(
                labelText: '이름',
                hintText: '예: 홍길동',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final name = (value ?? '').trim();
                if (name.isEmpty) return '이름을 입력해주세요.';
                if (name.runes.length > 40 ||
                    RegExp(r'[\x00-\x1f\x7f]').hasMatch(name)) {
                  return '이름을 40자 이내로 입력해주세요.';
                }
                return null;
              },
              onFieldSubmitted: (_) => _next(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC928),
                  foregroundColor: const Color(0xFF3E2723),
                ),
                onPressed: _next,
                child: const Text('다음'),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }
}
