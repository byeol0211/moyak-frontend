import 'package:flutter/material.dart';

/// 백엔드 HTML 화면(`static/app/*`)의 `.status-bar`를 옮긴 상단 상태 표시줄.
class AppStatusBar extends StatelessWidget {
  const AppStatusBar({
    this.color = const Color(0xFF3E2723),
    this.backgroundColor,
    super.key,
  });

  final Color color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) => Container(
    height: 44,
    color: backgroundColor,
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '9:41',
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        ExcludeSemantics(
          child: Row(
            children: [
              Icon(Icons.signal_cellular_4_bar, color: color, size: 18),
              const SizedBox(width: 6),
              Icon(Icons.wifi, color: color, size: 18),
              const SizedBox(width: 6),
              Icon(Icons.battery_full, color: color, size: 20),
            ],
          ),
        ),
      ],
    ),
  );
}
