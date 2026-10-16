import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white,
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: 64,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              children: [
                Expanded(
                  child: _BottomNavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    label: '메인',
                    selected: selectedIndex == 0,
                    onTap: () => onSelected(0),
                  ),
                ),
                Expanded(
                  child: _BottomNavItem(
                    icon: Icons.location_on_outlined,
                    activeIcon: Icons.location_on,
                    label: '지도',
                    selected: selectedIndex == 1,
                    onTap: () => onSelected(1),
                  ),
                ),
                const Expanded(child: SizedBox()),
                Expanded(
                  child: _BottomNavItem(
                    icon: Icons.chat_bubble_outline,
                    activeIcon: Icons.chat_bubble,
                    label: '모약이',
                    selected: selectedIndex == 3,
                    onTap: () => onSelected(3),
                  ),
                ),
                Expanded(
                  child: _BottomNavItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    label: '마이',
                    selected: selectedIndex == 4,
                    onTap: () => onSelected(4),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              top: -18,
              child: Center(
                child: _CenterNavItem(
                  selected: selectedIndex == 2,
                  onTap: () => onSelected(2),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: SizedBox.expand(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            selected ? activeIcon : icon,
            color: selected ? brandYellow : const Color(0xFF8D7F79),
            size: 24,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: selected ? brandYellow : const Color(0xFF8D7F79),
              fontSize: 10,
              height: 1,
            ),
          ),
        ],
      ),
    ),
  );
}

class _CenterNavItem extends StatelessWidget {
  const _CenterNavItem({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: SizedBox(
      width: 76,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: brandYellow,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const _StethoscopeMark(),
          ),
          const SizedBox(height: 4),
          Text(
            '상담하기',
            style: TextStyle(
              color: selected ? brandYellow : const Color(0xFF8D7F79),
              fontSize: 10,
              height: 1,
            ),
          ),
        ],
      ),
    ),
  );
}

class _StethoscopeMark extends StatelessWidget {
  const _StethoscopeMark();

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(size: Size(30, 30), painter: _StethoscopePainter(ink));
}

class _StethoscopePainter extends CustomPainter {
  const _StethoscopePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final tubing = Path()
      ..moveTo(7, 4)
      ..lineTo(7, 11)
      ..cubicTo(7, 17, 10, 19, 15, 19)
      ..cubicTo(20, 19, 23, 17, 23, 11)
      ..lineTo(23, 4)
      ..moveTo(15, 19)
      ..lineTo(15, 23)
      ..cubicTo(15, 26, 19, 27, 22, 25);
    canvas.drawPath(tubing, stroke);
    canvas.drawCircle(const Offset(23, 24), 3, stroke);
    canvas.drawLine(const Offset(5, 3), const Offset(9, 3), stroke);
    canvas.drawLine(const Offset(21, 3), const Offset(25, 3), stroke);
  }

  @override
  bool shouldRepaint(covariant _StethoscopePainter oldDelegate) =>
      oldDelegate.color != color;
}
