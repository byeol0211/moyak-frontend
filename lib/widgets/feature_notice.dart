import 'package:flutter/material.dart';

void showFeatureNotice(BuildContext context, [String? message]) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message ?? '준비 중인 기능이에요. 연결이 완료되면 이용할 수 있어요.')),
  );
}

class PreviewBanner extends StatelessWidget {
  const PreviewBanner({super.key});

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFFFE7AC),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          '화면 미리보기 · 예시 데이터이며 실제 상담·구매가 진행되지 않습니다.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    ),
  );
}
