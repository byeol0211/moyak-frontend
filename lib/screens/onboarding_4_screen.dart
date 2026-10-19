import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'login_page.dart';

const _background = Color(0xFFFFFDE7);
const _darkBrown = Color(0xFF3E2723);
const _labelBrown = Color(0xFF7D6D6A);
const _brandYellow = Color(0xFFFFD54F);
const _inactiveDot = Color(0xFFEFEBE9);

class Onboarding4Screen extends StatelessWidget {
  const Onboarding4Screen({this.onSkip, this.onStart, super.key});

  final VoidCallback? onSkip;
  final VoidCallback? onStart;

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final previewWidth = (constraints.maxWidth - 62)
                .clamp(0.0, 339.0)
                .toDouble();

            return Stack(
              fit: StackFit.expand,
              children: [
                Column(
                  children: [
                    const _StatusBar(),
                    _SkipAction(onPressed: onSkip),
                    const SizedBox(height: 59),
                    const _IntroText(),
                    const SizedBox(height: 23),
                    Expanded(
                      child: ClipRect(
                        child: OverflowBox(
                          alignment: Alignment.topCenter,
                          minHeight: 0,
                          maxHeight: double.infinity,
                          child: _MapPhonePreview(width: previewWidth),
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _BottomControls(onStart: onStart),
                ),
              ],
            );
          },
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

class _SkipAction extends StatelessWidget {
  const _SkipAction({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            backgroundColor: const Color(0x143E2723),
            foregroundColor: _darkBrown,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: const Text('건너뛰기'),
        ),
      ),
    ),
  );
}

class _IntroText extends StatelessWidget {
  const _IntroText();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 32),
    child: Column(
      children: [
        Text(
          '가까운 자판기를 찾아보세요',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _darkBrown,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            height: 1.3,
          ),
        ),
        SizedBox(height: 12),
        Text(
          '실시간 재고 확인과 최단 경로 길찾기까지 스마트하게 제공합니다.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _labelBrown, fontSize: 15, height: 1.5),
        ),
      ],
    ),
  );
}

class _MapPhonePreview extends StatelessWidget {
  const _MapPhonePreview({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: width * 736 / 339,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 4),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Column(
            children: [
              const _PreviewStatusBar(),
              const Expanded(child: _MapPreview()),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PreviewStatusBar extends StatelessWidget {
  const _PreviewStatusBar();

  @override
  Widget build(BuildContext context) => Container(
    height: 30,
    color: const Color(0xFFF1EEE5),
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '9:41',
          style: TextStyle(
            color: _darkBrown,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        Row(
          children: [
            Icon(Icons.signal_cellular_4_bar, color: _darkBrown, size: 12),
            SizedBox(width: 3),
            Icon(Icons.wifi, color: _darkBrown, size: 12),
            SizedBox(width: 3),
            Icon(Icons.battery_full, color: _darkBrown, size: 15),
          ],
        ),
      ],
    ),
  );
}

class _MapPreview extends StatelessWidget {
  const _MapPreview();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Stack(
      fit: StackFit.expand,
      children: [
        const CustomPaint(painter: _StreetMapPainter()),
        Positioned(
          left: 12,
          right: 12,
          top: 12,
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x18000000),
                  offset: Offset(0, 3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(Icons.search, color: _labelBrown, size: 20),
                SizedBox(width: 8),
                Text(
                  '가까운 모약 자판기 검색',
                  style: TextStyle(color: _hintColor, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 12,
          top: constraints.maxHeight * 0.34,
          child: const _CampusLabel(),
        ),
        Positioned(
          left: constraints.maxWidth * 0.62,
          top: constraints.maxHeight * 0.34,
          child: const _VendingMarker(),
        ),
        Positioned(
          left: constraints.maxWidth * 0.62,
          top: constraints.maxHeight * 0.48,
          child: const _SelectedVendingMarker(),
        ),
        Positioned(
          left: constraints.maxWidth * 0.48,
          top: constraints.maxHeight * 0.60,
          child: const _CurrentLocationMarker(),
        ),
        Positioned(
          left: constraints.maxWidth * 0.20,
          top: constraints.maxHeight * 0.75,
          child: const _VendingMarker(),
        ),
        Positioned(
          left: constraints.maxWidth * 0.63,
          top: constraints.maxHeight * 0.78,
          child: const _VendingMarker(),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: constraints.maxHeight * 0.65,
          bottom: 0,
          child: const _SelectedVendingCard(),
        ),
      ],
    ),
  );
}

const _hintColor = Color(0xFF9A8D83);

class _CampusLabel extends StatelessWidget {
  const _CampusLabel();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: _labelBrown,
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.account_balance, color: Colors.white, size: 11),
        SizedBox(width: 4),
        Text(
          '학생회관',
          style: TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _VendingMarker extends StatelessWidget {
  const _VendingMarker();

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      Icon(Icons.location_on, color: Color(0xFF827F77), size: 25),
      Text(
        'VENDING MACHINE',
        style: TextStyle(
          color: Color(0xFF827F77),
          fontSize: 6,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _SelectedVendingMarker extends StatelessWidget {
  const _SelectedVendingMarker();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: _brandYellow,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time, color: Colors.white, size: 10),
            SizedBox(width: 3),
            Text(
              '3층관 2층',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      const Icon(Icons.place, color: _brandYellow, size: 17),
    ],
  );
}

class _CurrentLocationMarker extends StatelessWidget {
  const _CurrentLocationMarker();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0x5539BDF8),
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(color: Color(0x3339BDF8), blurRadius: 12),
          ],
        ),
        alignment: Alignment.center,
        child: Container(
          width: 21,
          height: 21,
          decoration: BoxDecoration(
            color: const Color(0xFF2196F3),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
        ),
      ),
      const SizedBox(height: 5),
      const Text(
        'CURRENT LOCATION',
        style: TextStyle(
          color: Color(0xFF71818A),
          fontSize: 7,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _SelectedVendingCard extends StatelessWidget {
  const _SelectedVendingCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      boxShadow: [
        BoxShadow(
          color: Color(0x18000000),
          offset: Offset(0, -3),
          blurRadius: 8,
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 32,
            height: 3,
            decoration: BoxDecoration(
              color: _fieldBorder,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Text(
              '3층관 2층 자판기',
              style: TextStyle(
                color: _darkBrown,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(width: 8),
            Text(
              '도보 3분',
              style: TextStyle(
                color: _brandYellow,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        const Text(
          '가까운 위치에서 필요한 약품을 확인해보세요.',
          style: TextStyle(color: _labelBrown, fontSize: 10),
        ),
      ],
    ),
  );
}

class _StreetMapPainter extends CustomPainter {
  const _StreetMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xFFF0EEE5), BlendMode.srcOver);

    final roadEdge = Paint()
      ..color = const Color(0xFFE5E0D5)
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;
    final roadFill = Paint()
      ..color = const Color(0xFFFFFEFA)
      ..strokeWidth = 17
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;

    final roads = [
      Path()
        ..moveTo(-size.width * 0.18, size.height * 0.58)
        ..lineTo(size.width * 0.76, -size.height * 0.08),
      Path()
        ..moveTo(size.width * 0.15, size.height * 1.05)
        ..lineTo(size.width * 1.12, size.height * 0.33),
      Path()
        ..moveTo(-size.width * 0.12, size.height * 0.12)
        ..lineTo(size.width * 0.86, size.height * 0.98),
      Path()
        ..moveTo(size.width * 0.58, size.height * 1.08)
        ..lineTo(size.width * 1.10, size.height * 0.63),
    ];

    for (final road in roads) {
      canvas.drawPath(road, roadEdge);
      canvas.drawPath(road, roadFill);
    }

    final buildingPaint = Paint()..color = const Color(0xFFDAD6CA);
    final buildings = [
      Rect.fromLTWH(size.width * 0.12, size.height * 0.08, 52, 34),
      Rect.fromLTWH(size.width * 0.60, size.height * 0.09, 46, 32),
      Rect.fromLTWH(size.width * 0.32, size.height * 0.23, 58, 38),
      Rect.fromLTWH(size.width * 0.79, size.height * 0.25, 40, 35),
      Rect.fromLTWH(size.width * 0.06, size.height * 0.40, 46, 38),
      Rect.fromLTWH(size.width * 0.48, size.height * 0.40, 44, 31),
      Rect.fromLTWH(size.width * 0.74, size.height * 0.49, 55, 37),
      Rect.fromLTWH(size.width * 0.20, size.height * 0.62, 53, 35),
      Rect.fromLTWH(size.width * 0.50, size.height * 0.72, 52, 34),
      Rect.fromLTWH(size.width * 0.06, size.height * 0.84, 42, 30),
      Rect.fromLTWH(size.width * 0.78, size.height * 0.83, 48, 36),
    ];

    for (final rect in buildings) {
      canvas.save();
      canvas.translate(rect.center.dx, rect.center.dy);
      canvas.rotate(-0.72);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: rect.width,
            height: rect.height,
          ),
          const Radius.circular(2),
        ),
        buildingPaint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _StreetMapPainter oldDelegate) => false;
}

const _fieldBorder = Color(0xFFEFEBE9);

class _BottomControls extends StatelessWidget {
  const _BottomControls({required this.onStart});

  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: _background,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _PageIndicator(),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: LoginPrimaryButton(
              label: '시작하기',
              onPressed: onStart ?? () {},
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}

class _PageIndicator extends StatelessWidget {
  const _PageIndicator();

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _PageDot(active: false),
      SizedBox(width: 8),
      _PageDot(active: false),
      SizedBox(width: 8),
      _PageDot(active: false),
      SizedBox(width: 8),
      _PageDot(active: true),
    ],
  );
}

class _PageDot extends StatelessWidget {
  const _PageDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) => Container(
    width: active ? 24 : 8,
    height: 8,
    decoration: BoxDecoration(
      color: active ? _brandYellow : _inactiveDot,
      borderRadius: BorderRadius.circular(4),
    ),
  );
}
