import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _mapCanvas = Color(0xFFF1EEE5);
const _mapRoadEdge = Color(0xFFE2DCCE);
const _mapRoad = Color(0xFFFFFEFA);
const _mapInk = Color(0xFF3E2723);
const _mapMuted = Color(0xFF8D7F79);
const _mapYellow = Color(0xFFFFD54F);

class MapScreen extends StatefulWidget {
  const MapScreen({required this.onOpenStore, super.key});

  final VoidCallback onOpenStore;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool _inventoryExpanded = false;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarColor: _mapCanvas,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
    child: SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          fit: StackFit.expand,
          children: [
            const CustomPaint(painter: _StreetMapPainter()),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: _mapMuted),
                  hintText: '가까운 모약 자판기 검색',
                  hintStyle: const TextStyle(color: _mapMuted, fontSize: 14),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Positioned(
              left: constraints.maxWidth * 0.28,
              top: constraints.maxHeight * 0.30,
              child: const _CampusMarker(),
            ),
            Positioned(
              left: constraints.maxWidth * 0.58,
              top: constraints.maxHeight * 0.31,
              child: const _VendingMarker(),
            ),
            Positioned(
              left: constraints.maxWidth * 0.63,
              top: constraints.maxHeight * 0.40,
              child: const _SelectedVendingMarker(),
            ),
            Positioned(
              left: constraints.maxWidth * 0.47,
              top: constraints.maxHeight * 0.47,
              child: const _CurrentLocationMarker(),
            ),
            Positioned(
              left: constraints.maxWidth * 0.24,
              top: constraints.maxHeight * 0.58,
              child: const _VendingMarker(),
            ),
            Positioned(
              left: constraints.maxWidth * 0.66,
              top: constraints.maxHeight * 0.59,
              child: const _VendingMarker(),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _StoreSheet(
                expanded: _inventoryExpanded,
                onToggle: () => setState(
                  () => _inventoryExpanded = !_inventoryExpanded,
                ),
                onOpenStore: widget.onOpenStore,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CampusMarker extends StatelessWidget {
  const _CampusMarker();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF705A50),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance, color: Colors.white, size: 12),
            SizedBox(width: 5),
            Text(
              '학생회관',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      const Icon(Icons.arrow_drop_down, color: Color(0xFF705A50), size: 18),
    ],
  );
}

class _VendingMarker extends StatelessWidget {
  const _VendingMarker();

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      CircleAvatar(
        radius: 20,
        backgroundColor: Color(0xFFD7D7D3),
        child: Icon(Icons.dns_outlined, color: Color(0xFF737773), size: 23),
      ),
      SizedBox(height: 3),
      Text(
        'VENDING MACHINE',
        style: TextStyle(
          color: Color(0xFF777B78),
          fontSize: 7,
          fontWeight: FontWeight.w500,
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _mapYellow,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on, color: Colors.white, size: 12),
            SizedBox(width: 3),
            Text(
              '3호관 2층',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      const Icon(Icons.arrow_drop_down, color: _mapYellow, size: 18),
      const _VendingMarker(),
    ],
  );
}

class _CurrentLocationMarker extends StatelessWidget {
  const _CurrentLocationMarker();

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      SizedBox(
        width: 54,
        height: 70,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              top: 3,
              child: CircleAvatar(
                radius: 25,
                backgroundColor: Color(0x4039BDF8),
              ),
            ),
            Positioned(
              top: 10,
              child: CircleAvatar(
                radius: 17,
                backgroundColor: Color(0xFF16A9E8),
                child: CircleAvatar(
                  radius: 8,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 5,
                    backgroundColor: Color(0xFF168FF0),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 33,
              child: Icon(Icons.location_on, color: Color(0xFF13AFCB), size: 34),
            ),
          ],
        ),
      ),
      Text(
        'CURRENT LOCATION',
        style: TextStyle(
          color: Color(0xFF6C8791),
          fontSize: 8,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

class _StoreSheet extends StatelessWidget {
  const _StoreSheet({
    required this.expanded,
    required this.onToggle,
    required this.onOpenStore,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onOpenStore;

  @override
  Widget build(BuildContext context) => Container(
    height: expanded ? 396 : 212,
    padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      boxShadow: [
        BoxShadow(
          color: Color(0x10000000),
          blurRadius: 12,
          offset: Offset(0, -3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9E7),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Row(
          children: [
            Text(
              '3호관 2층 자판기',
              style: TextStyle(
                color: _mapInk,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 10),
            _WalkingTimeBadge(),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          '인하대학교 3호관 IT융합공학과 2층 로비 엘리베이터 앞',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: _mapMuted, fontSize: 12),
        ),
        const Divider(height: 28, color: Color(0xFFEDE9E7)),
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '실시간 재고',
                    style: TextStyle(color: _mapMuted, fontSize: 12),
                  ),
                  SizedBox(height: 3),
                  Text(
                    '여유 있음 (80%)',
                    style: TextStyle(
                      color: Color(0xFF00B957),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 44,
              child: FilledButton(
                onPressed: expanded ? onOpenStore : onToggle,
                style: FilledButton.styleFrom(
                  backgroundColor: _mapYellow,
                  foregroundColor: expanded ? _mapInk : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(expanded ? '상세 보기' : '재고 상품보기'),
              ),
            ),
          ],
        ),
        if (expanded) ...[
          const Divider(height: 28, color: Color(0xFFEDE9E7)),
          const Text(
            '재고 상품',
            style: TextStyle(
              color: _mapInk,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const _InventoryRow(
            name: '타이레놀 500mg',
            detail: '열·진통제 · 3,000원',
            count: '24개',
          ),
          const SizedBox(height: 6),
          const _InventoryRow(
            name: '판콜에이 내복액',
            detail: '감기약 · 3,500원',
            count: '12개',
          ),
          const SizedBox(height: 6),
          const _InventoryRow(
            name: '밴드 세트',
            detail: '상처 보호 · 2,000원',
            count: '8개',
          ),
        ],
      ],
    ),
  );
}

class _InventoryRow extends StatelessWidget {
  const _InventoryRow({
    required this.name,
    required this.detail,
    required this.count,
  });

  final String name;
  final String detail;
  final String count;

  @override
  Widget build(BuildContext context) => Container(
    height: 44,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFCF5),
      border: Border.all(color: const Color(0xFFF2EBDD)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: _mapInk,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                detail,
                style: const TextStyle(
                  color: _mapMuted,
                  fontSize: 9,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFECA6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count,
            style: const TextStyle(
              color: _mapInk,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _WalkingTimeBadge extends StatelessWidget {
  const _WalkingTimeBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF6D8),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Text(
      '도보 3분',
      style: TextStyle(
        color: _mapYellow,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _StreetMapPainter extends CustomPainter {
  const _StreetMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(_mapCanvas, BlendMode.srcOver);
    final roadBorder = Paint()
      ..color = _mapRoadEdge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.square;
    final road = Paint()
      ..color = _mapRoad
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.square;
    final roads = [
      Path()
        ..moveTo(-size.width * 0.15, size.height * 0.46)
        ..lineTo(size.width * 0.78, -size.height * 0.06),
      Path()
        ..moveTo(size.width * 0.10, size.height * 0.85)
        ..lineTo(size.width * 1.12, size.height * 0.24),
      Path()
        ..moveTo(size.width * 0.22, -size.height * 0.08)
        ..lineTo(size.width * 1.08, size.height * 0.83),
      Path()
        ..moveTo(-size.width * 0.10, size.height * 0.92)
        ..lineTo(size.width * 0.98, size.height * 0.12),
    ];
    for (final path in roads) {
      canvas.drawPath(path, roadBorder);
      canvas.drawPath(path, road);
    }

    final buildingPaint = Paint()..color = const Color(0xFFD9D5CA);
    final buildings = [
      Rect.fromLTWH(size.width * .30, size.height * .08, 42, 30),
      Rect.fromLTWH(size.width * .63, size.height * .05, 50, 34),
      Rect.fromLTWH(size.width * .48, size.height * .23, 46, 36),
      Rect.fromLTWH(size.width * .12, size.height * .28, 50, 35),
      Rect.fromLTWH(size.width * .78, size.height * .32, 46, 35),
      Rect.fromLTWH(size.width * .29, size.height * .49, 52, 35),
      Rect.fromLTWH(size.width * .62, size.height * .56, 44, 33),
      Rect.fromLTWH(size.width * .10, size.height * .67, 48, 35),
      Rect.fromLTWH(size.width * .45, size.height * .76, 54, 34),
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
