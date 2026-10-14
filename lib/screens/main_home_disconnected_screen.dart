import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/app_status_bar.dart';

const _canvas = Color(0xFFF2EBDD);
const _darkBrown = Color(0xFF3E2723);
const _secondaryBrown = Color(0xFF8D7F79);
const _brandYellow = Color(0xFFFFD54F);

class MainHomeDisconnectedScreen extends StatelessWidget {
  const MainHomeDisconnectedScreen({
    required this.onScanQr,
    required this.onRescanDevice,
    this.isScanning = false,
    super.key,
  });

  final VoidCallback onScanQr;
  final VoidCallback onRescanDevice;
  final bool isScanning;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppStatusBar(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HomeHeader(onScanQr: onScanQr),
                    const SizedBox(height: 26),
                    const _HomeInfoBanner(),
                    const SizedBox(height: 20),
                    Expanded(
                      child: _DisconnectedCard(
                        onRescanDevice: onRescanDevice,
                        isScanning: isScanning,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class MainHomeConnectedScreen extends StatelessWidget {
  const MainHomeConnectedScreen({
    required this.machineName,
    required this.onScanQr,
    required this.onOpenStore,
    this.isLoadingStore = false,
    super.key,
  });

  /// 지도에서 고르거나 QR로 연결한 자판기 이름.
  final String machineName;
  final VoidCallback onScanQr;

  /// 자판기 재고를 조회한 뒤 스토어로 이동한다.
  final VoidCallback onOpenStore;
  final bool isLoadingStore;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppStatusBar(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HomeHeader(onScanQr: onScanQr),
                    const SizedBox(height: 26),
                    const _HomeInfoBanner(),
                    const SizedBox(height: 20),
                    Expanded(
                      child: _ConnectedCard(
                        machineName: machineName,
                        onOpenStore: onOpenStore,
                        isLoadingStore: isLoadingStore,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
  const _DisconnectedCard({
    required this.onRescanDevice,
    required this.isScanning,
  });

  final VoidCallback onRescanDevice;
  final bool isScanning;

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
          child: Center(
            child: Image.asset(
              'assets/figma/moyak_2.png',
              width: 200,
              height: 188,
              fit: BoxFit.contain,
              semanticLabel: '자판기를 찾는 모약 마스코트',
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
          style: TextStyle(color: _secondaryBrown, fontSize: 12, height: 1.35),
        ),
        const SizedBox(height: 20),
        const Divider(height: 1, color: Color(0xFFF0ECE7)),
        const SizedBox(height: 22),
        SizedBox(
          height: 48,
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isScanning ? null : onRescanDevice,
            icon: isScanning
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(
                      color: _brandYellow,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.refresh, size: 20),
            label: Text(isScanning ? '주변 기기 탐색 중...' : '기기 재탐색'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _brandYellow,
              disabledForegroundColor: _brandYellow,
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
  const _ConnectedCard({
    required this.machineName,
    required this.onOpenStore,
    required this.isLoadingStore,
  });

  final String machineName;
  final VoidCallback onOpenStore;
  final bool isLoadingStore;

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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.circle, color: Color(0xFF20C878), size: 8),
              const SizedBox(width: 6),
              Text(
                '$machineName 연동됨',
                style: const TextStyle(
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
              'assets/figma/moyak_1.png',
              width: 200,
              height: 200,
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
          style: TextStyle(color: _secondaryBrown, fontSize: 12, height: 1.35),
        ),
        const SizedBox(height: 20),
        const Divider(height: 1, color: Color(0xFFF0ECE7)),
        const SizedBox(height: 22),
        SizedBox(
          height: 50,
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: isLoadingStore ? null : onOpenStore,
            icon: isLoadingStore
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.shopping_bag_outlined, size: 20),
            label: Text(isLoadingStore ? '재고 조회 중...' : '상품 구매하기'),
            style: FilledButton.styleFrom(
              backgroundColor: _brandYellow,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _brandYellow.withValues(alpha: 0.7),
              disabledForegroundColor: Colors.white,
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
