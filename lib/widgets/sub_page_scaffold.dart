import 'package:flutter/material.dart';

import 'app_status_bar.dart';

const subPageBackground = Color(0xFFF5F5F3);
const subPageInk = Color(0xFF3E2723);
const subPageMuted = Color(0xFF7D6D6A);

/// 백엔드 HTML의 `.sub-header`(뒤로가기 + 가운데 제목) 화면 틀.
/// 내 상담 내역, 전자 구매 허가서처럼 마이페이지에서 들어가는 화면에서 쓴다.
class SubPageScaffold extends StatelessWidget {
  const SubPageScaffold({
    required this.title,
    required this.child,
    this.bottomNavigationBar,
    super.key,
  });

  final String title;
  final Widget child;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: subPageBackground,
    bottomNavigationBar: bottomNavigationBar,
    body: SafeArea(
      bottom: false,
      child: Column(
        children: [
          const AppStatusBar(color: subPageInk),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  tooltip: '이전 화면',
                  icon: const Icon(Icons.chevron_left, color: subPageInk),
                ),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: subPageInk,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    ),
  );
}

/// 목록이 비었거나 불러오는 중일 때의 안내 문구 (`.h-empty`).
class SubPageMessage extends StatelessWidget {
  const SubPageMessage(this.text, {this.error = false, super.key});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 40),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: error ? const Color(0xFFC0392B) : const Color(0xFF8A7A70),
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.6,
      ),
    ),
  );
}
