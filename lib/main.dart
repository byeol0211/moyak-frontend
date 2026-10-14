import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart' show AuthRepository;

import 'data/demo_data.dart';
import 'data/models.dart';
import 'kakao_config.dart';
import 'screens/chatbot_screen.dart';
import 'screens/consult_history_screen.dart';
import 'screens/login_page.dart';
import 'screens/main_home_disconnected_screen.dart';
import 'screens/map_screen/map_screen.dart';
import 'screens/consultation_screen.dart';
import 'screens/permission_screen.dart';
import 'screens/permit_list_screen.dart';
import 'screens/qr_camera_page.dart';
import 'screens/screen_flows.dart';
import 'utils/format.dart';
import 'widgets/app_status_bar.dart';

const pageBackground = Color(0xFFFFFBE8);
const splashBackground = Color(0xFFFFFDE7);
const brandYellow = Color(0xFFF1C744);
const ink = Color(0xFF252525);
const mutedInk = Color(0xFF8C8B82);

void main() {
  if (kakaoJavaScriptKey.isNotEmpty) {
    AuthRepository.initialize(
      appKey: kakaoJavaScriptKey,
      baseUrl: kakaoSiteDomain,
    );
  }
  runApp(const MoyakApp());
}

class MoyakApp extends StatelessWidget {
  const MoyakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MOYAK',
      theme: ThemeData(
        scaffoldBackgroundColor: pageBackground,
        colorScheme: ColorScheme.fromSeed(seedColor: brandYellow),
        fontFamily: 'Arial',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 17,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFEDEBD9)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: brandYellow, width: 2),
          ),
          hintStyle: const TextStyle(color: mutedInk, fontSize: 15),
        ),
      ),
      home: const SplashPage(),
    );
  }
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        final navigator = Navigator.of(context);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => PermissionScreen(
              onAllow: () => navigator.pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => _createLoginPage(navigator),
                ),
              ),
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarColor: splashBackground,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: splashBackground,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
    child: Scaffold(
      backgroundColor: splashBackground,
      body: SafeArea(
        child: Column(
          children: [
            const AppStatusBar(),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 411),
                    child: AspectRatio(
                      aspectRatio: 411 / 292,
                      child: Image.asset(
                        'assets/figma/splash_welcome.png',
                        fit: BoxFit.cover,
                        semanticLabel: '모약이에 온 걸 환영해! 약 자판기 마스코트',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

LoginPage _createLoginPage(NavigatorState navigator) => LoginPage(
  onLogin: () => _openOnboardingFlow(navigator),
  onSignup: () => navigator.push(
    MaterialPageRoute<void>(
      builder: (_) =>
          SignupFlow(onComplete: () => _openOnboardingFlow(navigator)),
    ),
  ),
);

void _openOnboardingFlow(NavigatorState navigator) {
  navigator.pushReplacement(
    MaterialPageRoute<void>(
      builder: (_) => OnboardingFlow(
        onComplete: () => navigator.pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const AppShell()),
        ),
      ),
    ),
  );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 56,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: brandYellow,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      child: Text(label),
    ),
  );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selectedIndex = 0;
  bool _isScanningDevices = false;
  bool _isLoadingStore = false;

  /// 연결된(선택한) 자판기. null이면 연결 없음 홈을 보여준다.
  VendingMachine? _connectedMachine;

  // 상담 탭에 들어올 때마다 새 상담 요청이 시작되도록 키를 바꾼다.
  int _consultSession = 0;
  bool _consultFromChatbot = false;

  void selectTab(int index) {
    if (index == 2) {
      _openConsultation(fromChatbot: false);
      return;
    }
    setState(() => selectedIndex = index);
  }

  void _openConsultation({required bool fromChatbot}) {
    if (selectedIndex == 2 && !fromChatbot) return;
    setState(() {
      _consultSession++;
      _consultFromChatbot = fromChatbot;
      selectedIndex = 2;
    });
  }

  // 기기 탐색 API가 아직 없어 주변 자판기를 찾은 것처럼 잠시 기다린 뒤 연결한다.
  Future<void> _rescanDevices() async {
    if (_isScanningDevices) return;
    setState(() => _isScanningDevices = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isScanningDevices = false);
    _connectMachine(demoConnectedMachine);
  }

  void _openQrScanner() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (routeContext) => QrCameraPage(
          onBack: () => Navigator.of(routeContext).pop(),
          onConnected: () {
            Navigator.of(routeContext).pop();
            _connectMachine(demoConnectedMachine);
          },
        ),
      ),
    );
  }

  void _connectMachine(VendingMachine machine) {
    setState(() {
      _connectedMachine = machine;
      selectedIndex = 0;
    });
  }

  /// 연결된 자판기의 재고를 조회한 뒤 그 재고로 스토어를 연다.
  Future<void> _openStore() async {
    final machine = _connectedMachine;
    if (machine == null || _isLoadingStore) return;
    setState(() => _isLoadingStore = true);
    try {
      final items = await fetchMachineStock(machine.id);
      if (!mounted) return;
      setState(() => _isLoadingStore = false);
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => StorePage(machineName: machine.name, items: items),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingStore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('자판기 재고를 불러오지 못했어요. 다시 시도해주세요.')),
      );
    }
  }

  void _pushSubPage(WidgetBuilder builder) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: builder));

  /// 마이페이지에서 들어간 화면의 하단 메뉴: 쌓인 화면을 닫고 해당 탭으로 이동한다.
  Widget _subPageNavigation(Route<dynamic>? shellRoute) => AppBottomNavigation(
    selectedIndex: 4,
    onSelected: (index) => _returnToTab(shellRoute, index),
  );

  void _returnToTab(Route<dynamic>? shellRoute, int index) {
    Navigator.of(context).popUntil((route) => route == shellRoute);
    selectTab(index);
  }

  void _openConsultHistory() {
    final shellRoute = ModalRoute.of(context);
    _pushSubPage(
      (_) => ConsultHistoryScreen(
        bottomNavigationBar: _subPageNavigation(shellRoute),
        onOpenDetail: (record) => _pushSubPage(
          (_) => Scaffold(
            bottomNavigationBar: _subPageNavigation(shellRoute),
            body: ConsultationScreen(
              record: record,
              onScanQr: _openQrScanner,
              onOpenChatbot: () => _returnToTab(shellRoute, 3),
            ),
          ),
        ),
      ),
    );
  }

  void _openPermitList() {
    final shellRoute = ModalRoute.of(context);
    _pushSubPage(
      (_) =>
          PermitListScreen(bottomNavigationBar: _subPageNavigation(shellRoute)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final machine = _connectedMachine;
    final pages = [
      machine != null
          ? MainHomeConnectedScreen(
              machineName: machine.name,
              onScanQr: _openQrScanner,
              onOpenStore: _openStore,
              isLoadingStore: _isLoadingStore,
            )
          : MainHomeDisconnectedScreen(
              onScanQr: _openQrScanner,
              onRescanDevice: _rescanDevices,
              isScanning: _isScanningDevices,
            ),
      MapScreen(
        selectedMachineId: machine?.id,
        onSelectMachine: _connectMachine,
        onUnselectMachine: () => setState(() => _connectedMachine = null),
      ),
      // 상담 요청은 탭에 들어올 때마다 새로 시작되도록 선택됐을 때만 만든다.
      if (selectedIndex == 2)
        ConsultationScreen(
          key: ValueKey(_consultSession),
          direct: !_consultFromChatbot,
          onScanQr: _openQrScanner,
          onOpenChatbot: () => selectTab(3),
        )
      else
        const SizedBox.shrink(),
      ChatPage(
        onScanQr: _openQrScanner,
        onRequestConsult: () => _openConsultation(fromChatbot: true),
      ),
      Mypage(
        onOpenConsultHistory: _openConsultHistory,
        onOpenPermit: _openPermitList,
        onOpenInventory: () => _pushSubPage(
          (_) => InventoryRequestPage(
            onTabSelected: (index) {
              Navigator.of(context).pop();
              selectTab(index);
            },
          ),
        ),
      ),
    ];
    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: pages),
      bottomNavigationBar: AppBottomNavigation(
        selectedIndex: selectedIndex,
        onSelected: selectTab,
      ),
    );
  }
}

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

class Mypage extends StatelessWidget {
  const Mypage({
    required this.onOpenConsultHistory,
    required this.onOpenPermit,
    required this.onOpenInventory,
    super.key,
  });

  final VoidCallback onOpenConsultHistory;
  final VoidCallback onOpenPermit;
  final VoidCallback onOpenInventory;

  @override
  Widget build(BuildContext context) => AppPage(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFE9DCC8),
              radius: 19,
              child: Icon(Icons.person, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '홍길동',
                        style: TextStyle(
                          color: ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 7),
                      _VerifiedBadge(),
                    ],
                  ),
                  SizedBox(height: 3),
                  Text(
                    'gildong.hong@gmail.com',
                    style: TextStyle(color: mutedInk, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFCF3),
              border: Border.all(color: const Color(0xFFFFD866)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.credit_card, color: brandYellow, size: 15),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '간편 결제 카드 등록됨',
                        style: TextStyle(
                          color: ink,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        '국민카드 **** 1294 (자판기 다이렉트 결제)',
                        style: TextStyle(color: mutedInk, fontSize: 8),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: mutedInk, size: 17),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: ActionCard(
                icon: Icons.receipt_long,
                title: '전자 구매 허가서',
                description: '약사 발급 전자 증명서',
                onTap: onOpenPermit,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ActionCard(
                icon: Icons.shopping_cart_outlined,
                title: '재고 신청하기',
                description: '없는 약품 수요 요청',
                onTap: onOpenInventory,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MypageMenuItem(
          label: '내 상담 내역 (처방·상담 요약)',
          onTap: onOpenConsultHistory,
        ),
        ...['공지사항 및 서비스 안내', '고객 지원', '앱 설정', '계정 보안', '로그아웃'].map(
          (label) =>
              _MypageMenuItem(label: label, destructive: label == '로그아웃'),
        ),
      ],
    ),
  );
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFFE7F8EC),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Text(
      '본인인증 완료',
      style: TextStyle(
        color: Color(0xFF20A85A),
        fontSize: 7,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _MypageMenuItem extends StatelessWidget {
  const _MypageMenuItem({
    required this.label,
    this.destructive = false,
    this.onTap,
  });

  final String label;
  final bool destructive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 31,
    child: InkWell(
      onTap: onTap ?? () {},
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFEDE7E4))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: destructive ? Colors.red : ink,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: mutedInk, size: 16),
          ],
        ),
      ),
    ),
  );
}

class ActionCard extends StatelessWidget {
  const ActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
    this.description = '',
    super.key,
  });
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      height: 72,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 23,
            height: 23,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF8DE),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: brandYellow, size: 13),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: ink,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: mutedInk, fontSize: 7),
          ),
        ],
      ),
    ),
  );
}

class AppPage extends StatelessWidget {
  const AppPage({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 28, 20, 20),
    super.key,
  });
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      children: [
        const AppStatusBar(),
        Expanded(
          child: Padding(padding: padding, child: child),
        ),
      ],
    ),
  );
}

class InventoryRequestPage extends StatefulWidget {
  const InventoryRequestPage({required this.onTabSelected, super.key});

  final ValueChanged<int> onTabSelected;

  @override
  State<InventoryRequestPage> createState() => _InventoryRequestPageState();
}

class _InventoryRequestPageState extends State<InventoryRequestPage> {
  final _searchController = TextEditingController();
  final _selectedMedicines = <String>{};
  String _selectedVendingMachine = '3호관 2층 자판기';

  static const _medicines = [
    _InventoryMedicine('어린이 부루펜시럽', '해열 진통제'),
    _InventoryMedicine('겔포스엠 현탁액', '제산 소화제'),
    _InventoryMedicine('이지엔6 프로 연질캡슐', '소염 진통제'),
  ];

  List<_InventoryMedicine> get _filteredMedicines {
    final query = _searchController.text.trim();
    if (query.isEmpty) return _medicines;
    return _medicines
        .where((medicine) => medicine.name.contains(query))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (_selectedMedicines.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('신청할 약품을 선택해주세요.')));
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _InventoryRequestAcceptedDialog(
        onConfirm: () => Navigator.of(dialogContext).pop(),
      ),
    );

    if (mounted) setState(_selectedMedicines.clear);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F5F5),
    body: SafeArea(
      child: Column(
        children: [
          const AppStatusBar(),
          SizedBox(
            height: 44,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.chevron_left, size: 23),
                ),
                const Expanded(
                  child: Text(
                    '재고 신청',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              children: [
                const _InventoryFieldLabel('자판기 선택'),
                const SizedBox(height: 8),
                Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFECE7E3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedVendingMachine,
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: mutedInk,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: '3호관 2층 자판기',
                          child: Row(
                            children: [
                              Icon(
                                Icons.grid_view,
                                color: brandYellow,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                '3호관 2층 자판기',
                                style: TextStyle(
                                  color: ink,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: '학생회관 1층 자판기',
                          child: Text('학생회관 1층 자판기'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedVendingMachine = value);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const _InventoryFieldLabel('신청할 약품 검색'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 42,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(color: ink, fontSize: 12),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, size: 18),
                      prefixIconColor: mutedInk,
                      hintText: '약품명을 입력하세요 (예: 타이레놀)',
                      hintStyle: const TextStyle(color: mutedInk, fontSize: 11),
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFECE7E3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFECE7E3)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '자판기 품절 인기 의약품',
                  style: TextStyle(
                    color: mutedInk,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                for (final medicine in _filteredMedicines) ...[
                  _InventoryMedicineTile(
                    medicine: medicine,
                    selected: _selectedMedicines.contains(medicine.name),
                    onChanged: (value) => setState(
                      () => value
                          ? _selectedMedicines.add(medicine.name)
                          : _selectedMedicines.remove(medicine.name),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 10),
            child: SizedBox(
              width: double.infinity,
              height: 46,
              child: PrimaryButton(label: '신청하기', onPressed: _submitRequest),
            ),
          ),
          AppBottomNavigation(
            selectedIndex: 4,
            onSelected: widget.onTabSelected,
          ),
        ],
      ),
    ),
  );
}

class _InventoryRequestAcceptedDialog extends StatelessWidget {
  const _InventoryRequestAcceptedDialog({required this.onConfirm});

  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.white,
    insetPadding: const EdgeInsets.symmetric(horizontal: 20),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 324),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '재고 접수되었습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ink,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              '날짜와 위치에 따라 소요시간이 달라질 수 있습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(color: mutedInk, fontSize: 12),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: 158,
              height: 46,
              child: FilledButton(
                onPressed: onConfirm,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD66B),
                  foregroundColor: ink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                  ),
                ),
                child: const Text('확인'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _InventoryMedicine {
  const _InventoryMedicine(this.name, this.category);

  final String name;
  final String category;
}

class _InventoryFieldLabel extends StatelessWidget {
  const _InventoryFieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: ink,
      fontSize: 11,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _InventoryMedicineTile extends StatelessWidget {
  const _InventoryMedicineTile({
    required this.medicine,
    required this.selected,
    required this.onChanged,
  });

  final _InventoryMedicine medicine;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => onChanged(!selected),
    borderRadius: BorderRadius.circular(12),
    child: Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFECE7E3)),
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
                  medicine.name,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  medicine.category,
                  style: const TextStyle(color: mutedInk, fontSize: 9),
                ),
              ],
            ),
          ),
          const Text(
            '남은 수량 0개',
            style: TextStyle(color: Colors.red, fontSize: 9),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: selected,
              onChanged: (value) => onChanged(value ?? false),
              side: const BorderSide(color: brandYellow, width: 1.2),
              activeColor: brandYellow,
              checkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    ),
  );
}

class StorePage extends StatefulWidget {
  const StorePage({required this.machineName, required this.items, super.key});

  /// 재고를 조회한 자판기 이름과 그 재고 목록.
  final String machineName;
  final List<StockItem> items;

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  final _searchController = TextEditingController();
  int _selectedTab = 0;
  int _selectedCategory = 0;
  bool _searchOpen = false;

  late final _products = widget.items.map(_StoreProduct.fromStock).toList();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_StoreProduct> get _visibleProducts {
    Iterable<_StoreProduct> products = _products;
    if (_selectedTab == 1) {
      products = products.where(
        (product) => _selectedCategory == 0 ? !product.locked : product.locked,
      );
    }
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      products = products.where((product) => product.name.contains(query));
    }
    return products.toList();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
    child: Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            const AppStatusBar(backgroundColor: Colors.white),
            _StoreHeader(
              title: widget.machineName,
              searchOpen: _searchOpen,
              searchController: _searchController,
              onBack: () => Navigator.of(context).pop(),
              onSearchToggle: () => setState(() {
                _searchOpen = !_searchOpen;
                if (!_searchOpen) _searchController.clear();
              }),
              onSearchChanged: (_) => setState(() {}),
            ),
            _StoreTabs(
              selectedIndex: _selectedTab,
              onSelected: (index) => setState(() => _selectedTab = index),
            ),
            _StoreCategoryFilters(
              selectedIndex: _selectedCategory,
              onSelected: (index) => setState(() => _selectedCategory = index),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(26, 4, 26, 24),
                itemCount: _visibleProducts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.82,
                ),
                itemBuilder: (context, index) => _StoreProductCard(
                  product: _visibleProducts[index],
                  onTap: () {},
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _StoreHeader extends StatelessWidget {
  const _StoreHeader({
    required this.title,
    required this.searchOpen,
    required this.searchController,
    required this.onBack,
    required this.onSearchToggle,
    required this.onSearchChanged,
  });

  final String title;
  final bool searchOpen;
  final TextEditingController searchController;
  final VoidCallback onBack;
  final VoidCallback onSearchToggle;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) => Container(
    height: 52,
    color: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        SizedBox(
          width: 40,
          child: IconButton(
            onPressed: onBack,
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.chevron_left, color: ink, size: 28),
          ),
        ),
        Expanded(
          child: searchOpen
              ? TextField(
                  controller: searchController,
                  autofocus: true,
                  onChanged: onSearchChanged,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: ink, fontSize: 15),
                  decoration: const InputDecoration(
                    hintText: '상품 검색',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                )
              : Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        SizedBox(
          width: 40,
          child: IconButton(
            onPressed: onSearchToggle,
            padding: EdgeInsets.zero,
            icon: Icon(
              searchOpen ? Icons.close : Icons.search,
              color: ink,
              size: 25,
            ),
          ),
        ),
      ],
    ),
  );
}

class _StoreTabs extends StatelessWidget {
  const _StoreTabs({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    height: 50,
    color: Colors.white,
    child: Row(
      children: [
        _StoreTab(
          label: '빠른 구매',
          selected: selectedIndex == 0,
          onTap: () => onSelected(0),
        ),
        _StoreTab(
          label: '카테고리',
          selected: selectedIndex == 1,
          onTap: () => onSelected(1),
        ),
      ],
    ),
  );
}

class _StoreTab extends StatelessWidget {
  const _StoreTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? brandYellow : Colors.transparent,
              width: 1,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? brandYellow : mutedInk,
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    ),
  );
}

class _StoreCategoryFilters extends StatelessWidget {
  const _StoreCategoryFilters({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 60,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
      children: [
        _CategoryChip(
          label: '일반 상비품',
          selected: selectedIndex == 0,
          onTap: () => onSelected(0),
        ),
        const SizedBox(width: 8),
        _CategoryChip(
          label: '의약품',
          selected: selectedIndex == 1,
          locked: true,
          onTap: () => onSelected(1),
        ),
      ],
    ),
  );
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.locked = false,
  });

  final String label;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? const Color(0xFFFFD866) : Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: ink,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (locked) ...[
              const SizedBox(width: 4),
              const Icon(Icons.lock, color: mutedInk, size: 12),
            ],
          ],
        ),
      ),
    ),
  );
}

enum _ProductKind { tylenol, cough, digestive, saline, generic }

class _StoreProduct {
  const _StoreProduct(
    this.name,
    this.category,
    this.price,
    this.kind, {
    this.locked = false,
    this.soldOut = false,
  });

  /// 자판기 재고 한 건을 스토어 카드로 바꾼다. 의약품 분류는 약사 허가가 필요해 잠금 표시한다.
  factory _StoreProduct.fromStock(StockItem item) {
    final category = item.category ?? '일반 상비';
    final locked = category == '의약품';
    final price = item.price;
    return _StoreProduct(
      item.name,
      locked ? '의약품 🔒' : category,
      price == null ? '가격 정보 없음' : formatPrice(price),
      _kindFor(item.name),
      locked: locked,
      soldOut: item.stock <= 0,
    );
  }

  static _ProductKind _kindFor(String name) {
    if (name.contains('타이레놀')) return _ProductKind.tylenol;
    if (name.contains('판콜') || name.contains('기침')) return _ProductKind.cough;
    if (name.contains('훼스탈') || name.contains('베아제') || name.contains('소화')) {
      return _ProductKind.digestive;
    }
    if (name.contains('식염수')) return _ProductKind.saline;
    return _ProductKind.generic;
  }

  final String name;
  final String category;
  final String price;
  final _ProductKind kind;
  final bool locked;
  final bool soldOut;
}

class _StoreProductCard extends StatelessWidget {
  const _StoreProductCard({required this.product, required this.onTap});

  final _StoreProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: product.locked ? brandYellow : const Color(0xFFECE7E3),
            width: product.locked ? 1.2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: const Color(0xFFF8F8F7),
                    child: _ProductArtwork(kind: product.kind),
                  ),
                  if (product.locked)
                    const Positioned(
                      top: 9,
                      right: 9,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: Color(0xFFFF9B1A),
                        child: Icon(Icons.lock, color: Colors.white, size: 14),
                      ),
                    ),
                  if (product.soldOut)
                    const ColoredBox(
                      color: Color(0x805D4E4A),
                      child: Center(
                        child: Text(
                          '품절',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: mutedInk, fontSize: 10),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      product.price,
                      style: TextStyle(
                        color: product.soldOut
                            ? const Color(0xFFBCAAA4)
                            : brandYellow,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
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

class _ProductArtwork extends StatelessWidget {
  const _ProductArtwork({required this.kind});

  final _ProductKind kind;

  @override
  Widget build(BuildContext context) => Center(
    child: switch (kind) {
      _ProductKind.tylenol => const _TylenolPack(),
      _ProductKind.cough => const _CoughMedicinePack(),
      _ProductKind.digestive => const _DigestivePack(),
      _ProductKind.saline => const _SalineBottle(),
      _ProductKind.generic => const Icon(
        Icons.medication_outlined,
        color: Color(0xFFBCAAA4),
        size: 48,
      ),
    },
  );
}

class _TylenolPack extends StatelessWidget {
  const _TylenolPack();

  @override
  Widget build(BuildContext context) => Container(
    width: 94,
    height: 68,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE7E4E1)),
      boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 8)],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(height: 5, color: const Color(0xFFE43D45)),
        const Padding(
          padding: EdgeInsets.fromLTRB(7, 7, 5, 0),
          child: Text(
            'TYLENOL',
            style: TextStyle(
              color: Color(0xFFD9232E),
              fontSize: 13,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 7),
          child: Text(
            'ER 650 mg',
            style: TextStyle(
              color: Color(0xFF263A5D),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Spacer(),
        Container(height: 8, color: const Color(0xFFF2F2F0)),
      ],
    ),
  );
}

class _CoughMedicinePack extends StatelessWidget {
  const _CoughMedicinePack();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Container(
        width: 92,
        height: 72,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F3EF),
          border: Border.all(color: const Color(0xFFD7D4CC)),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Column(
          children: [
            Container(height: 8, color: const Color(0xFF37434A)),
            const Spacer(),
            Container(
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF91C4C8),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 5),
      Container(
        width: 22,
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF4F3),
          border: Border.all(color: const Color(0xFFD5DAD8)),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(7),
            bottom: Radius.circular(4),
          ),
        ),
        child: const Align(
          alignment: Alignment.center,
          child: ColoredBox(
            color: Color(0xFF82BFC5),
            child: SizedBox(height: 18),
          ),
        ),
      ),
    ],
  );
}

class _DigestivePack extends StatelessWidget {
  const _DigestivePack();

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: -0.05,
    child: Container(
      width: 104,
      height: 70,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F0ED),
        border: Border.all(color: const Color(0xFFE4E0DC)),
        boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 7)],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DIGESTIVE HARMONY',
            style: TextStyle(color: Color(0xFF88909A), fontSize: 5),
          ),
          Spacer(),
          Align(
            alignment: Alignment.centerRight,
            child: Icon(
              Icons.medication_outlined,
              color: Color(0xFFD6D1C9),
              size: 28,
            ),
          ),
        ],
      ),
    ),
  );
}

class _SalineBottle extends StatelessWidget {
  const _SalineBottle();

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 21,
        height: 10,
        decoration: BoxDecoration(
          color: const Color(0xFF55B7D2),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      Container(
        width: 43,
        height: 76,
        decoration: BoxDecoration(
          color: const Color(0xFFF9FCFC),
          border: Border.all(color: const Color(0xFFD2DADC)),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(7),
            bottom: Radius.circular(12),
          ),
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8)],
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              height: 31,
              width: double.infinity,
              color: const Color(0xFF37B7D9),
              alignment: Alignment.center,
              child: const Text(
                'STERILE\nSALINE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 7,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
