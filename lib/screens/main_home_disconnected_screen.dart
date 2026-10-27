import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/app_status_bar.dart';

const _canvas = Color(0xFFF2EBDD);
const _darkBrown = Color(0xFF3E2723);
const _secondaryBrown = Color(0xFF8D7F79);
const _brandYellow = Color(0xFFFFD54F);

class _ScrollableHome extends StatelessWidget {
  const _ScrollableHome({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: SizedBox(
          height: constraints.maxHeight.clamp(
            700 * MediaQuery.textScalerOf(context).scale(1),
            double.infinity,
          ),
          child: child,
        ),
      ),
    ),
  );
}

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
      child: _ScrollableHome(
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
    this.paired = false,
    this.onOpenStore,
    this.onChangeMachine,
    super.key,
  });

  /// 지도에서 고르거나 QR로 연결한 자판기 이름.
  final String machineName;
  final bool paired;
  final VoidCallback onScanQr;

  /// 마스코트를 누르면 이 자판기의 구매(재고) 화면을 연다.
  final VoidCallback? onOpenStore;

  /// '선택됨' 배지를 누르면 다른 자판기로 바꾸는 창을 연다.
  final VoidCallback? onChangeMachine;

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
      child: _ScrollableHome(
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
                        paired: paired,
                        onOpenStore: onOpenStore,
                        onChangeMachine: onChangeMachine,
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

class _HomeInfoBanner extends StatefulWidget {
  const _HomeInfoBanner();

  @override
  State<_HomeInfoBanner> createState() => _HomeInfoBannerState();
}

const _ads = [
  (title: '급한 의약품이 있다면? 자판기에서 바로!', subtitle: '약국이 닫혔다면? 의약품 자동판매기에서 바로 구매'),
  (title: '무슨 약이 필요한지 모르겠다면? 모약이에게!', subtitle: '약품 정보부터 비대면 상담 전 가벼운 문진까지'),
  (
    title: '약사와의 상담? 비대면 화상 상담으로 빠르게!',
    subtitle: '약사에게 원격 허가서를 받아 자판기에서 빠르게 구매',
  ),
  (title: 'QR로 자판기에서 간단하게 구매하자!', subtitle: '허가서 받은 약품은 QR로 절차 없이 빠르게 수령 가능'),
];

class _HomeInfoBannerState extends State<_HomeInfoBanner> {
  static const _interval = Duration(seconds: 4);

  // 양쪽으로 계속 넘길 수 있도록 큰 페이지 수의 가운데에서 시작한다.
  static final _initialPage = _ads.length * 1000;

  final _controller = PageController(initialPage: _initialPage);
  Timer? _timer;
  int _page = _initialPage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 메인 탭이 화면에 보일 때만(TickerMode 활성) 자동으로 넘긴다.
    if (TickerMode.valuesOf(context).enabled) {
      _restartTimer();
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _restartTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_interval, (_) {
      if (!_controller.hasClients) return;
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 68,
    child: NotificationListener<ScrollStartNotification>(
      // 손으로 넘기면 자동 넘김 시간을 처음부터 다시 잰다.
      onNotification: (notification) {
        if (notification.dragDetails != null &&
            TickerMode.valuesOf(context).enabled) {
          _restartTimer();
        }
        return false;
      },
      child: PageView.builder(
        controller: _controller,
        onPageChanged: (page) => setState(() => _page = page),
        itemBuilder: (context, page) {
          final index = page % _ads.length;
          return _AdCard(
            title: _ads[index].title,
            subtitle: _ads[index].subtitle,
            pageLabel: '${index + 1}/${_ads.length}',
            semanticsLabel: page == _page
                ? '광고 ${index + 1}/${_ads.length}'
                : null,
          );
        },
      ),
    ),
  );
}

class _AdCard extends StatelessWidget {
  const _AdCard({
    required this.title,
    required this.subtitle,
    required this.pageLabel,
    this.semanticsLabel,
  });

  final String title;
  final String subtitle;
  final String pageLabel;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticsLabel,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: _darkBrown,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    subtitle,
                    style: const TextStyle(
                      color: _secondaryBrown,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          DecoratedBox(
            decoration: const BoxDecoration(
              color: Color(0xFFF4EEE2),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              child: Text(
                pageLabel,
                style: const TextStyle(
                  color: _darkBrown,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
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
  Widget build(BuildContext context) => _HomeCard(
    child: Column(
      children: [
        const Expanded(
          child: _HomeCardContent(
            badge: '자판기 연결 없음',
            badgeColor: _secondaryBrown,
            badgeDot: Color(0xFFBCAAA4),
            badgeBackground: Color(0xFFF6F5F3),
            image: 'assets/figma/moyak_2.png',
            imageLabel: '자판기를 찾는 모약 마스코트',
            title: '가까운 자판기가 있나요?',
            description: '스마트 기기와 자판기를 연동하고 안전하게 의약품을 처방 및 결제하세요.',
          ),
        ),
        const SizedBox(height: 16),
        const Divider(height: 1, color: Color(0xFFF0ECE7)),
        const SizedBox(height: 18),
        SizedBox(
          height: 50,
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
            label: Text(isScanning ? '주변 기기를 탐색합니다...' : '기기 재탐색'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _brandYellow,
              disabledForegroundColor: _brandYellow,
              side: const BorderSide(color: _brandYellow, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
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

class _ConnectedCard extends StatelessWidget {
  const _ConnectedCard({
    required this.machineName,
    required this.paired,
    this.onOpenStore,
    this.onChangeMachine,
  });

  final String machineName;
  final bool paired;
  final VoidCallback? onOpenStore;
  final VoidCallback? onChangeMachine;

  @override
  Widget build(BuildContext context) => _HomeCard(
    child: _HomeCardContent(
      onImageTap: onOpenStore,
      imageTapLabel: '$machineName 구매 화면 열기',
      onBadgeTap: onChangeMachine,
      badgeTapHint: '다른 자판기로 변경',
      badge: '$machineName ${paired ? '연동됨' : '선택됨'}',
      badgeColor: const Color(0xFF13B965),
      badgeDot: const Color(0xFF20C878),
      badgeBackground: const Color(0xFFE8FBF0),
      badgeBorder: const Color(0xFF8AE0AE),
      image: 'assets/figma/moyak_1.png',
      imageLabel: '모약 자판기 마스코트',
      title: paired ? '자판기 연결 화면입니다' : '이용할 자판기를 선택했어요',
      description:
          '재고는 지도에서 자판기를 눌러 확인할 수 있어요. 실제 연결은 QR 스캔으로, 구매와 결제는 자판기에서 진행합니다.',
    ),
  );
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({required this.child});

  final Widget child;

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
    child: child,
  );
}

/// 연결 성공·실패 카드 공통: 배지·마스코트·안내 문구를 한 묶음으로
/// 가운데에 모은다. 공간이 모자라면 마스코트만 줄어든다.
class _HomeCardContent extends StatelessWidget {
  const _HomeCardContent({
    required this.badge,
    required this.badgeColor,
    required this.badgeDot,
    required this.badgeBackground,
    required this.image,
    required this.imageLabel,
    required this.title,
    required this.description,
    this.badgeBorder,
    this.onImageTap,
    this.imageTapLabel,
    this.onBadgeTap,
    this.badgeTapHint,
  });

  final String badge;
  final Color badgeColor;
  final Color badgeDot;
  final Color badgeBackground;
  final Color? badgeBorder;
  final String image;
  final String imageLabel;
  final String title;
  final String description;
  final VoidCallback? onImageTap;
  final String? imageTapLabel;
  final VoidCallback? onBadgeTap;
  final String? badgeTapHint;

  @override
  Widget build(BuildContext context) {
    Widget mascot = Image.asset(
      image,
      width: 300,
      height: 300,
      fit: BoxFit.contain,
      semanticLabel: imageLabel,
    );
    if (onImageTap != null) {
      mascot = Tooltip(
        message: imageTapLabel ?? imageLabel,
        child: Semantics(
          button: true,
          label: imageTapLabel,
          child: InkResponse(onTap: onImageTap, radius: 150, child: mascot),
        ),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 누를 수 있으면 오른쪽에 변경 표시를 붙인다.
        Semantics(
          button: onBadgeTap != null,
          hint: badgeTapHint,
          child: Material(
            color: badgeBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: badgeBorder == null
                  ? BorderSide.none
                  : BorderSide(color: badgeBorder!),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onBadgeTap,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  9,
                  onBadgeTap == null ? 16 : 10,
                  9,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: badgeDot, size: 10),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        badge,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (onBadgeTap != null) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.expand_more, color: badgeColor, size: 22),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Flexible(child: mascot),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _darkBrown,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _secondaryBrown,
            fontSize: 13.5,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
