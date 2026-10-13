import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _canvas = Color(0xFFF2EBDD);
const _darkBrown = Color(0xFF3E2723);
const _secondaryBrown = Color(0xFF8D7F79);
const _brandYellow = Color(0xFFFFD54F);

class MainHomeDisconnectedScreen extends StatelessWidget {
  const MainHomeDisconnectedScreen({
    required this.onScanQr,
    required this.onRescanDevice,
    super.key,
  });

  final VoidCallback onScanQr;
  final VoidCallback onRescanDevice;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarColor: _canvas,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
    child: Container(
      color: _canvas,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HomeHeader(onScanQr: onScanQr),
              const SizedBox(height: 26),
              const _HomeInfoBanner(),
              const SizedBox(height: 20),
              Expanded(
                child: _DisconnectedCard(onRescanDevice: onRescanDevice),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class MainHomeConnectedScreen extends StatelessWidget {
  const MainHomeConnectedScreen({
    required this.onScanQr,
    required this.onOpenStore,
    super.key,
  });

  final VoidCallback onScanQr;
  final VoidCallback onOpenStore;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarColor: _canvas,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
    child: Container(
      color: _canvas,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HomeHeader(onScanQr: onScanQr),
              const SizedBox(height: 26),
              const _HomeInfoBanner(),
              const SizedBox(height: 20),
              Expanded(child: _ConnectedCard(onOpenStore: onOpenStore)),
            ],
          ),
        ),
      ),
    ),
  );
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.onScanQr});

  final VoidCallback onScanQr;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(
        child: Text(
          'MOYAK',
          style: TextStyle(
            color: _darkBrown,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        elevation: 2,
        shadowColor: const Color(0x18000000),
        child: InkWell(
          onTap: onScanQr,
          borderRadius: BorderRadius.circular(24),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.qr_code_scanner, color: _darkBrown, size: 18),
                SizedBox(width: 6),
                Text(
                  'QR 스캔',
                  style: TextStyle(
                    color: _darkBrown,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

class _HomeInfoBanner extends StatelessWidget {
  const _HomeInfoBanner();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '급한 의약품이 있다면? 자판기에서 바로!',
                style: TextStyle(
                  color: _darkBrown,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '약품 정보부터 비대면 의약품 화상 상담까지 스마트하게',
                style: TextStyle(color: _secondaryBrown, fontSize: 11),
              ),
            ],
          ),
        ),
        SizedBox(width: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Color(0xFFF4EEE2),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            child: Text(
              '1/4',
              style: TextStyle(
                color: _darkBrown,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _DisconnectedCard extends StatelessWidget {
  const _DisconnectedCard({required this.onRescanDevice});

  final VoidCallback onRescanDevice;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(
          color: Color(0x12000000),
          blurRadius: 16,
          offset: Offset(0, 7),
        ),
      ],
    ),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F5F3),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, color: Color(0xFFBCAAA4), size: 8),
              SizedBox(width: 6),
              Text(
                '자판기 연결 없음',
                style: TextStyle(
                  color: _secondaryBrown,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/figma/splash_mascot.png',
                  width: 180,
                  height: 216,
                  fit: BoxFit.contain,
                  semanticLabel: '모약 자판기 마스코트',
                ),
                Positioned(
                  left: constraints.maxWidth * 0.12,
                  top: constraints.maxHeight * 0.17,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: _darkBrown, width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x10000000),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '?',
                      style: TextStyle(
                        color: _darkBrown,
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Text(
          '가까운 자판기가 있나요?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _darkBrown,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '스마트 기기와 자판기를 연동하고 안전하게 의약품을 처방 및 결제하세요.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _secondaryBrown,
            fontSize: 12,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 20),
        const Divider(height: 1, color: Color(0xFFF0ECE7)),
        const SizedBox(height: 22),
        SizedBox(
          height: 48,
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onRescanDevice,
            icon: const Icon(Icons.refresh, size: 20),
            label: const Text('기기 재탐색'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _brandYellow,
              side: const BorderSide(color: _brandYellow, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ConnectedCard extends StatelessWidget {
  const _ConnectedCard({required this.onOpenStore});

  final VoidCallback onOpenStore;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(
          color: Color(0x12000000),
          blurRadius: 16,
          offset: Offset(0, 7),
        ),
      ],
    ),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFE8FBF0),
            border: Border.all(color: const Color(0xFF8AE0AE)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, color: Color(0xFF20C878), size: 8),
              SizedBox(width: 6),
              Text(
                '3호관 2층 자판기 연동됨',
                style: TextStyle(
                  color: Color(0xFF13B965),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Image.asset(
              'assets/figma/splash_mascot.png',
              width: 160,
              height: 205,
              fit: BoxFit.contain,
              semanticLabel: '모약 자판기 마스코트',
            ),
          ),
        ),
        const Text(
          '안전하게 연결되었습니다!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _darkBrown,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          '원하는 상비의약품을 자판기 스토어에서 직접 조회하고 간편하게 바로 구매해보세요.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _secondaryBrown,
            fontSize: 12,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 20),
        const Divider(height: 1, color: Color(0xFFF0ECE7)),
        const SizedBox(height: 22),
        SizedBox(
          height: 50,
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onOpenStore,
            icon: const Icon(Icons.shopping_bag_outlined, size: 20),
            label: const Text('상품 구매하기'),
            style: FilledButton.styleFrom(
              backgroundColor: _brandYellow,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}