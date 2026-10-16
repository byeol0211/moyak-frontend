import 'package:flutter/material.dart';

/// Compatibility placeholder. SafeArea and the OS draw the actual status bar.
class AppStatusBar extends StatelessWidget {
  const AppStatusBar({
    this.color = const Color(0xFF3E2723),
    this.backgroundColor,
    super.key,
  });

  final Color color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
