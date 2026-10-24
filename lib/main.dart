import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart' show AuthRepository;

import 'data/consultation_api.dart';
import 'data/demo_data.dart';
import 'data/machine_api.dart';
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
import 'theme/app_theme.dart';
import 'screens/mypage.dart';
import 'widgets/app_bottom_navigation.dart';
export 'screens/store_page.dart' show StorePage;
import 'widgets/app_status_bar.dart';
import 'config/app_config.dart';
import 'data/app_session.dart';
import 'widgets/feature_notice.dart';

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
      builder: (context, child) => ValueListenableBuilder<bool>(
        valueListenable: AppConfig.preview,
        builder: (context, preview, _) => Column(
          children: [
            if (preview) const PreviewBanner(),
            Expanded(
              child: preview
                  ? MediaQuery.removePadding(
                      context: context,
                      removeTop: true,
                      child: child!,
                    )
                  : child!,
            ),
          ],
        ),
      ),
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
  navigator.pushAndRemoveUntil(
    MaterialPageRoute<void>(
      builder: (_) => OnboardingFlow(
        onComplete: () => navigator.pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const AppShell()),
        ),
      ),
    ),
    (_) => false,
  );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void initState() {
    super.initState();
    AppSession.instance.addListener(_sessionChanged);
  }

  void _sessionChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppSession.instance.removeListener(_sessionChanged);
    super.dispose();
  }

  int selectedIndex = 0;

  /// 연결된(선택한) 자판기. null이면 연결 없음 홈을 보여준다.
  VendingMachine? _connectedMachine;
  bool _machinePaired = false;

  // 진행 중인 상담은 탭을 옮겨도 유지하고, 끝났거나 취소됐으면 새로 요청한다.
  int _consultSession = 0;
  bool _consultFromChatbot = false;
  bool _consultClosed = false;

  void selectTab(int index) {
    if (index == 2) {
      _openConsultation(fromChatbot: false);
      return;
    }
    setState(() => selectedIndex = index);
  }

  void _openConsultation({required bool fromChatbot}) {
    final current = AppSession.instance.consultation;
    // 실제 모드에서 상담이 아직 만들어지는 중이면(current == null) 같은 화면을 이어서 보여준다.
    final active =
        _consultSession > 0 &&
        !_consultClosed &&
        (current == null ||
            (current.status == ConsultStatus.pending &&
                current.endedAt == null));
    setState(() {
      if (!active) {
        _consultSession++;
        _consultClosed = false;
        _consultFromChatbot = fromChatbot;
        if (AppConfig.preview.value) {
          AppSession.instance.cancelConsultation();
        } else {
          AppSession.instance.clearCallRoom();
          AppSession.instance.cancelConsultation();
        }
      }
      selectedIndex = 2;
    });
  }

  String _requireUserId() {
    final userId = AppSession.instance.userId;
    if (userId == null) throw StateError('사용자 정보를 확인하지 못했어요. 다시 로그인해주세요.');
    return userId;
  }

  Future<List<ConsultRecord>> _loadConsultHistory() async {
    final api = ConsultationApi();
    try {
      return await api.history(_requireUserId());
    } finally {
      api.close();
    }
  }

  Future<List<PermitRecord>> _loadPermits() async {
    final api = ConsultationApi();
    try {
      return await api.permits(_requireUserId());
    } finally {
      api.close();
    }
  }

  // 기기 재탐색: 내 위치(없으면 기본 위치) 기준 가장 가까운 자판기를 찾아
  // 지도에서 고른 것처럼 연결된 홈으로 보낸다.
  bool _isScanningDevices = false;

  Future<void> _rescanDevices() async {
    if (_isScanningDevices) return;
    setState(() => _isScanningDevices = true);
    try {
      final results = await Future.wait([
        _scanPosition().then((position) {
          if (!mounted) return null;
          if (position == null && !AppConfig.preview.value) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '현재 위치를 확인하지 못해 기본 위치 기준으로 검색해요.',
                  style: TextStyle(fontSize: 12),
                ),
                duration: Duration(seconds: 4),
              ),
            );
          }
          return findNearestMachine(
            latitude: position?.latitude ?? _defaultScanLatitude,
            longitude: position?.longitude ?? _defaultScanLongitude,
          );
        }),
        // 탐색 중 안내가 너무 짧게 스쳐 가지 않도록 최소 시간을 둔다.
        Future<void>.delayed(const Duration(milliseconds: 1500)),
      ]);
      if (!mounted) return;
      final machine = results.first as VendingMachine?;
      if (machine == null) {
        showFeatureNotice(context, '주변에서 연결할 자판기를 찾지 못했어요. QR 스캔으로 연결해주세요.');
      } else {
        _connectMachine(machine);
      }
    } catch (_) {
      if (mounted) {
        showFeatureNotice(context, '주변 기기를 찾지 못했어요. 잠시 후 다시 시도해주세요.');
      }
    } finally {
      if (mounted) setState(() => _isScanningDevices = false);
    }
  }

  // 지도 화면과 같은 기본 위치(위치 권한이 없을 때 사용).
  static const _defaultScanLatitude = 37.4509;
  static const _defaultScanLongitude = 126.6539;

  Future<Position?> _scanPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  void _openQrScanner() {
    MachineScanResult? scanned;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (routeContext) => QrCameraPage(
          onBack: () => Navigator.of(routeContext).pop(),
          // 실제 모드: 스캔한 QR로 자판기에 로그인한다(POST /vending/scan).
          // 실패하면 예외가 QR 화면에 그대로 전달돼 이유와 다시 스캔을 보여준다.
          onScan: AppConfig.preview.value
              ? null
              : (qr) async {
                  scanned = await scanMachineQr(
                    machineId: qr.machineId,
                    qrToken: qr.token,
                    userId: _requireUserId(),
                  );
                },
          onConnected: () {
            Navigator.of(routeContext).pop();
            final result = scanned;
            if (result != null) {
              _connectMachine(result.machine, paired: true);
              final drug = result.approvedDrugName;
              showFeatureNotice(
                context,
                drug == null
                    ? '자판기와 연동됐어요. 자판기 화면에서 이어서 진행해주세요.'
                    : '자판기와 연동됐어요. 승인된 약품($drug)을 자판기에서 수령하실 수 있어요.',
              );
            } else if (AppConfig.preview.value) {
              _connectMachine(demoConnectedMachine, paired: true);
            }
          },
        ),
      ),
    );
  }

  void _connectMachine(VendingMachine machine, {bool paired = false}) {
    setState(() {
      _connectedMachine = machine;
      _machinePaired = paired;
      selectedIndex = 0;
    });
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
        loadRecords: AppConfig.preview.value ? null : _loadConsultHistory,
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
      (_) => PermitListScreen(
        bottomNavigationBar: _subPageNavigation(shellRoute),
        loadRecords: AppConfig.preview.value ? null : _loadPermits,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final machine = _connectedMachine;
    final pages = [
      machine != null
          ? MainHomeConnectedScreen(
              machineName: machine.name,
              paired: _machinePaired,
              onScanQr: _openQrScanner,
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
      if (_consultSession > 0)
        ConsultationScreen(
          key: ValueKey(_consultSession),
          isActive: selectedIndex == 2,
          onOpenConsultation: () => setState(() => selectedIndex = 2),
          room: AppSession.instance.callRoom,
          chat: AppSession.instance.callChat,
          direct: !_consultFromChatbot,
          onScanQr: _openQrScanner,
          onOpenChatbot: () => selectTab(3),
          onClosed: () => _consultClosed = true,
        )
      else
        const SizedBox.shrink(),
      ChatPage(
        onScanQr: _openQrScanner,
        onRequestConsult: () => _openConsultation(fromChatbot: true),
      ),
      Mypage(
        onLogout: _logout,
        onOpenConsultHistory: _openConsultHistory,
        onOpenPermit: _openPermitList,
        onOpenInventory: () => _pushSubPage(
          (_) => const AppPage(child: Center(child: Text('재고 신청은 준비 중이에요.'))),
        ),
      ),
    ];
    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: [
          for (var i = 0; i < pages.length; i++)
            TickerMode(enabled: i == selectedIndex, child: pages[i]),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        selectedIndex: selectedIndex,
        onSelected: selectTab,
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃하면 이 기기의 임시 사용자 정보와 미리보기 기록이 초기화됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await AppSession.instance.logout();
      if (!mounted) return;
      AppConfig.preview.value = false;
      final navigator = Navigator.of(context);
      navigator.pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => _createLoginPage(navigator)),
        (_) => false,
      );
    } catch (_) {
      if (mounted) showFeatureNotice(context, '로그아웃하지 못했어요. 다시 시도해주세요.');
    }
  }
}
