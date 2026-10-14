import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'screens/login_page.dart';
import 'screens/main_home_disconnected_screen.dart';
import 'screens/map_screen/map_screen.dart';
import 'screens/permission_screen.dart';
import 'screens/qr_camera_page.dart';
import 'screens/screen_flows.dart';
import 'screens/video_consultation_page.dart';
import 'widgets/app_status_bar.dart';

const pageBackground = Color(0xFFFFFBE8);
const splashBackground = Color(0xFFFFFDE7);
const brandYellow = Color(0xFFF1C744);
const ink = Color(0xFF252525);
const mutedInk = Color(0xFF8C8B82);

void main() => runApp(const MoyakApp());

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
      builder: (_) => SignupFlow(
        onComplete: () => _openOnboardingFlow(navigator),
      ),
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

class BrandMark extends StatelessWidget {
  const BrandMark({required this.size, super.key});

  final double size;

  @override
  Widget build(BuildContext context) => Text(
    'MOYAK',
    textAlign: TextAlign.center,
    style: TextStyle(
      color: brandYellow,
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: 2,
    ),
  );
}

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  int step = 0;

  @override
  Widget build(BuildContext context) {
    final titles = ['아이디 설정', '비밀번호 설정', '본인 인증'];
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => step == 0
                        ? Navigator.of(context).pop()
                        : setState(() => step--),
                    icon: const Icon(Icons.chevron_left, size: 30),
                  ),
                  const Expanded(
                    child: Text(
                      '회원가입',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    titles[step],
                    style: const TextStyle(
                      color: brandYellow,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${step + 1} / 3',
                    style: const TextStyle(
                      color: mutedInk,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (step + 1) / 3,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFEDE9E7),
                  color: brandYellow,
                ),
              ),
              const SizedBox(height: 25),
              Expanded(child: _SignupStep(step: step)),
              PrimaryButton(
                label: step == 2 ? '완료' : '다음',
                onPressed: () => step == 2
                    ? Navigator.of(context).pop()
                    : setState(() => step++),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignupStep extends StatelessWidget {
  const _SignupStep({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    if (step == 0) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '사용하실 아이디를 입력해주세요',
            style: TextStyle(color: mutedInk, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(hintText: '아이디 입력'),
                ),
              ),
              SizedBox(width: 10),
              SizedBox(
                width: 88,
                height: 52,
                child: _DarkButton(label: '중복확인'),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '✓ 사용 가능한 아이디입니다.',
            style: TextStyle(color: Color(0xFF418844), fontSize: 13),
          ),
        ],
      );
    }
    if (step == 1) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LabeledField(label: '비밀번호', hint: '비밀번호를 입력해주세요', obscureText: true),
          SizedBox(height: 18),
          LabeledField(
            label: '비밀번호 확인',
            hint: '비밀번호를 다시 입력해주세요',
            obscureText: true,
          ),
          SizedBox(height: 8),
          Text(
            '✓ 영문, 숫자, 특수문자 조합 8자 이상 충족',
            style: TextStyle(color: Color(0xFF418844), fontSize: 13),
          ),
        ],
      );
    }
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '원활한 약품 결제를 위해 인증 방식을 선택해주세요',
          style: TextStyle(color: mutedInk, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 20),
        VerificationCard(
          icon: Icons.mail_outline,
          title: '이메일 인증',
          description: '등록된 이메일 계정으로 인증 메일을\n보냅니다.',
          selected: true,
        ),
        SizedBox(height: 12),
        VerificationCard(
          icon: Icons.shield_outlined,
          title: '간편인증',
          description: '카카오, 토스 등 민간인증서로 빠르게\n인증합니다.',
          selected: false,
        ),
      ],
    );
  }
}

class LabeledField extends StatelessWidget {
  const LabeledField({
    required this.label,
    required this.hint,
    this.obscureText = false,
    super.key,
  });

  final String label;
  final String hint;
  final bool obscureText;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: mutedInk,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hint,
          suffixIcon: obscureText
              ? const Icon(
                  Icons.visibility_off_outlined,
                  color: Color(0xFFB9AAA4),
                )
              : null,
        ),
      ),
    ],
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

class SocialDivider extends StatelessWidget {
  const SocialDivider({super.key});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: Divider(color: Color(0xFFEDE7E4))),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          'SNS 간편 로그인',
          style: TextStyle(color: Color(0xFFB9AAA4), fontSize: 12),
        ),
      ),
      const Expanded(child: Divider(color: Color(0xFFEDE7E4))),
    ],
  );
}

class SocialButton extends StatelessWidget {
  const SocialButton({
    required this.label,
    required this.color,
    this.textColor = Colors.white,
    this.outlined = false,
    super.key,
  });

  final String label;
  final Color color;
  final Color textColor;
  final bool outlined;

  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: outlined ? Border.all(color: const Color(0xFFE8E1DE)) : null,
    ),
    child: Center(
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class _DarkButton extends StatelessWidget {
  const _DarkButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: () {},
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFF392927),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    child: Text(label),
  );
}

class VerificationCard extends StatelessWidget {
  const VerificationCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(
        color: selected ? brandYellow : const Color(0xFFEDE7E4),
        width: selected ? 2 : 1,
      ),
      boxShadow: selected
          ? null
          : const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
    ),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: selected
              ? const Color(0xFFFFF9D8)
              : const Color(0xFFF5F3F2),
          foregroundColor: selected ? brandYellow : mutedInk,
          child: Icon(icon),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                description,
                style: const TextStyle(
                  color: mutedInk,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        CircleAvatar(
          radius: 12,
          backgroundColor: selected ? brandYellow : const Color(0xFFEDE9E7),
          foregroundColor: Colors.white,
          child: Icon(selected ? Icons.check : Icons.check, size: 16),
        ),
      ],
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
  bool _isVendingMachineConnected = false;
  bool _isScanningDevices = false;

  void selectTab(int index) => setState(() => selectedIndex = index);

  // 기기 탐색 API가 아직 없어 주변 자판기를 찾은 것처럼 잠시 기다린 뒤 연결한다.
  Future<void> _rescanDevices() async {
    if (_isScanningDevices) return;
    setState(() => _isScanningDevices = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isScanningDevices = false);
    _completeVendingMachineConnection();
  }

  void _completeVendingMachineConnection() {
    setState(() {
      _isVendingMachineConnected = true;
      selectedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _isVendingMachineConnected
          ? MainHomeConnectedScreen(
              onScanQr: () => selectTab(2),
              onOpenStore: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const StorePage()),
              ),
            )
          : MainHomeDisconnectedScreen(
              onScanQr: () => selectTab(2),
              onRescanDevice: _rescanDevices,
              isScanning: _isScanningDevices,
            ),
      MapScreen(
        onOpenStore: () => Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => const StorePage())),
      ),
      QrCameraPage(
        onBack: () => selectTab(0),
        onConnected: _completeVendingMachineConnection,
      ),
      const ChatPage(),
      Mypage(
        onOpenPermit: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const PermitListPage())),
        onOpenInventory: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => InventoryRequestPage(
              onTabSelected: (index) {
                Navigator.of(context).pop();
                selectTab(index);
              },
            ),
          ),
        ),
      ),
    ];
    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: pages),
      bottomNavigationBar: selectedIndex == 2
          ? null
          : AppBottomNavigation(
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
  Widget build(BuildContext context) => const CustomPaint(
    size: Size(30, 30),
    painter: _StethoscopePainter(ink),
  );
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

class HomePage extends StatelessWidget {
  const HomePage({required this.onOpenStore, super.key});

  final VoidCallback onOpenStore;

  @override
  Widget build(BuildContext context) => AppPage(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'MOYAK',
          style: TextStyle(
            color: ink,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 28),
        const InfoBanner(),
        const SizedBox(height: 20),
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 16,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4FFF0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '●  3호관 2층 자판기 연결됨',
                    style: TextStyle(
                      color: Color(0xFF16B967),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 65),
                const Icon(
                  Icons.medical_services_outlined,
                  size: 92,
                  color: brandYellow,
                ),
                const SizedBox(height: 32),
                const Text(
                  '안전하게 연결되었습니다!',
                  style: TextStyle(
                    color: ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '원하는 상비약품을 자판기 스토어에서 직접 조회하고\n편리하게 바로 구매해보세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: mutedInk, height: 1.4),
                ),
                const Spacer(),
                const Divider(color: Color(0xFFEDE7E4)),
                const SizedBox(height: 18),
                PrimaryButton(label: '상품 구매하기', onPressed: onOpenStore),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
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
                style: TextStyle(color: ink, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 5),
              Text(
                '약품 정보부터 비대면 의약품 화상 상담까지 스마트하게',
                style: TextStyle(color: mutedInk, fontSize: 11),
              ),
            ],
          ),
        ),
        Text('1/4', style: TextStyle(color: mutedInk, fontSize: 11)),
      ],
    ),
  );
}

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) => AppPage(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: '가까운 모약 자판기 검색',
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                color: const Color(0xFFE8E6DD),
                child: CustomPaint(
                  painter: MapPatternPainter(),
                  child: const SizedBox.expand(),
                ),
              ),
              const Center(
                child: Icon(
                  Icons.location_on,
                  size: 52,
                  color: Colors.lightBlue,
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '3호관 2층 자판기',
                        style: TextStyle(
                          color: ink,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '인하대학교 3호관 IT융합공학과 2층 로비 엘리베이터 앞',
                        style: TextStyle(color: mutedInk, fontSize: 12),
                      ),
                      Divider(height: 28),
                      Text(
                        '실시간 재고',
                        style: TextStyle(color: mutedInk, fontSize: 12),
                      ),
                      Text(
                        '여유 있음 (80%)',
                        style: TextStyle(
                          color: Color(0xFF00B957),
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
      ],
    ),
  );
}

class MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(.75)
      ..strokeWidth = 3;
    for (var x = -size.height; x < size.width + size.height; x += 70) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Mypage extends StatelessWidget {
  const Mypage({
    required this.onOpenPermit,
    required this.onOpenInventory,
    super.key,
  });

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
        ...[
          '공지사항 및 서비스 안내',
          '고객 지원',
          '앱 설정',
          '계정 보안',
          '로그아웃',
        ].map(
          (label) => _MypageMenuItem(
            label: label,
            destructive: label == '로그아웃',
          ),
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
  const _MypageMenuItem({required this.label, this.destructive = false});

  final String label;
  final bool destructive;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 31,
    child: InkWell(
      onTap: () {},
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

class QrPage extends StatefulWidget {
  const QrPage({required this.active, super.key});

  final bool active;

  @override
  State<QrPage> createState() => _QrPageState();
}

class _QrPageState extends State<QrPage> {
  bool _promptShown = false;

  @override
  void initState() {
    super.initState();
    if (widget.active) _scheduleBiometricPrompt();
  }

  @override
  void didUpdateWidget(covariant QrPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _scheduleBiometricPrompt();
  }

  void _scheduleBiometricPrompt() {
    if (_promptShown) return;
    _promptShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        barrierColor: const Color(0xB83E2723),
        builder: (dialogContext) => _BiometricPrompt(
          onCancel: () => Navigator.of(dialogContext).pop(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF3E2723),
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFF5F5F3),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
    child: Container(
      color: const Color(0xFF3E2723),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(
                    Icons.chevron_left,
                    color: Color(0xFF8B7770),
                    size: 26,
                  ),
                ),
                const Expanded(
                  child: Text(
                    'QR 코드 스캔',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF9A8780),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'QR 코드를 가이드 영역 안에 대주세요',
              style: TextStyle(
                color: Color(0xFFBCAAA4),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '본인인증 후 의약품 수령이 승인됩니다.',
              style: TextStyle(color: Color(0xFF8D7F79), fontSize: 10),
            ),
            const Expanded(child: SizedBox()),
          ],
        ),
      ),
    ),
  );
}

class _BiometricPrompt extends StatelessWidget {
  const _BiometricPrompt({required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.white,
    insetPadding: const EdgeInsets.symmetric(horizontal: 20),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFFFFBE5),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.fingerprint,
                color: Color(0xFFFFD54F),
                size: 26,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '생체 인증이 필요합니다',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF3E2723),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              '기기에 등록된 지문을 인식해주세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF8D7F79),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF0ECE9)),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              width: double.infinity,
              child: TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF8D7F79),
                  backgroundColor: const Color(0xFFF4F4F3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('취소'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class ChatPage extends StatefulWidget {
  const ChatPage({this.client, super.key});

  final http.Client? client;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final http.Client _client = widget.client ?? http.Client();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <Map<String, dynamic>>[];
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    if (widget.client == null) _client.close();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && _scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  });

  Future<void> _sendMessage([String? suggestedMessage]) async {
    final question = (suggestedMessage ?? _messageController.text).trim();
    if (question.isEmpty || _busy) return;
    final history = _messages.where((m) => m['complete'] == true).toList();
    final recent = history
        .skip(history.length > 20 ? history.length - 20 : 0)
        .map((m) => {'role': m['role'], 'content': m['content']})
        .toList();
    final message = <String, dynamic>{'role': 'user', 'content': question};
    setState(() {
      _busy = true;
      _error = null;
      _messages.add(message);
      _messageController.clear();
    });
    _scrollToBottom();
    try {
      const base = String.fromEnvironment('API_BASE_URL');
      final uri = (base.isEmpty ? Uri.base : Uri.parse(base)).resolve('/chat');
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'question': question, 'history': recent}),
          )
          .timeout(const Duration(seconds: 90));
      dynamic data;
      try {
        data = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        throw Exception('서버 응답을 읽지 못했습니다 (${response.statusCode}).');
      }
      if (response.statusCode != 200) {
        throw Exception(
          data is Map && data['detail'] is String
              ? data['detail']
              : '요청에 실패했습니다 (${response.statusCode}).',
        );
      }
      if (data['answer'] is! String) throw Exception('답변 형식이 올바르지 않습니다.');
      if (!mounted) return;
      setState(() {
        message['complete'] = true;
        _messages.add({
          'role': 'assistant',
          'content': data['answer'],
          'sources': data['sources'],
          'evidence': data['evidence'],
          'complete': true,
        });
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.remove(message);
          _error = '$e'.replaceFirst('Exception: ', '');
          _messageController.text = question;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _scrollToBottom();
      }
    }
  }

  void _openVideoConsultation() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const VideoConsultationPage()),
    );
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarColor: Color(0xFFF5F5F5),
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
    child: AppPage(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(width: 32),
                icon: const Icon(Icons.chevron_left, size: 24, color: ink),
              ),
              const CircleAvatar(
                radius: 15,
                backgroundColor: Color(0xFFFFF5CF),
                child: Icon(
                  Icons.medical_services_outlined,
                  color: brandYellow,
                  size: 17,
                ),
              ),
              const SizedBox(width: 7),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '모약이',
                      style: TextStyle(
                        color: ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      '● 상담 가능',
                      style: TextStyle(color: Color(0xFF18B55B), fontSize: 9),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _openVideoConsultation,
                icon: const Icon(Icons.call_outlined, color: mutedInk, size: 18),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.search, color: mutedInk, size: 18),
              ),
            ],
          ),
          const Divider(height: 1),
          const SizedBox(height: 12),
          const Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFFEFEDEC),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                child: Text(
                  '오늘',
                  style: TextStyle(color: mutedInk, fontSize: 9),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: EdgeInsets.zero,
              children: [
                const _BotMessage(
                  text: '안녕하세요! 자판기 건강 헬퍼 모약이입니다. 궁금한 약품이나 증상을 입력해주세요.',
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 31),
                  child: Wrap(
                    spacing: 6,
                    children: [
                      _ChatSuggestion(
                        label: '약품 정보',
                        onTap: () => _sendMessage('약품 정보를 알려주세요.'),
                      ),
                      _ChatSuggestion(
                        label: '상담하기',
                        onTap: _openVideoConsultation,
                      ),
                    ],
                  ),
                ),
                for (final message in _messages) ...[
                  const SizedBox(height: 14),
                  if (message['role'] == 'user')
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 250),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE39A),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Text(
                          message['content'] as String,
                          style: const TextStyle(
                            color: ink,
                            fontSize: 10,
                            height: 1.35,
                          ),
                        ),
                      ),
                    )
                  else
                    _BotMessage(
                      text: message['content'] as String,
                      evidence: message['evidence'] is List
                          ? message['evidence'] as List
                          : const [],
                      sources: message['sources'] is List
                          ? message['sources'] as List
                          : const [],
                    ),
                ],
                if (_busy) ...[
                  const SizedBox(height: 14),
                  const Padding(
                    padding: EdgeInsets.only(left: 31),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: brandYellow,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '약품 정보를 확인하고 있어요…',
                          style: TextStyle(color: mutedInk, fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                _error!,
                key: const Key('chat-error'),
                style: const TextStyle(color: Color(0xFFD84B2F), fontSize: 10),
              ),
            ),
          Row(
            children: [
              IconButton(
                onPressed: () {},
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: mutedInk,
                  fixedSize: const Size(32, 32),
                ),
                icon: const Icon(Icons.add, size: 17),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: TextField(
                    controller: _messageController,
                    maxLength: 4000,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    style: const TextStyle(color: ink, fontSize: 10),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '메시지를 입력하세요...',
                      hintStyle: const TextStyle(
                        color: mutedInk,
                        fontSize: 10,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              IconButton.filled(
                key: const Key('chat-send'),
                tooltip: '메시지 전송',
                onPressed: _busy ? null : _sendMessage,
                style: IconButton.styleFrom(
                  backgroundColor: brandYellow,
                  foregroundColor: ink,
                  fixedSize: const Size(32, 32),
                ),
                icon: const Icon(Icons.arrow_upward, size: 16),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _BotMessage extends StatelessWidget {
  const _BotMessage({
    required this.text,
    this.evidence = const [],
    this.sources = const [],
  });

  final String text;
  final List<dynamic> evidence;
  final List<dynamic> sources;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const CircleAvatar(
        radius: 12,
        backgroundColor: Color(0xFFFFF0B4),
        child: Icon(
          Icons.medical_services_outlined,
          color: brandYellow,
          size: 14,
        ),
      ),
      const SizedBox(width: 8),
      Flexible(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 250),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                text,
                style: const TextStyle(color: ink, fontSize: 10, height: 1.35),
              ),
              if (evidence.isNotEmpty)
                Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    iconColor: brandYellow,
                    collapsedIconColor: mutedInk,
                    title: const Text(
                      '답변 근거 보기',
                      style: TextStyle(
                        color: brandYellow,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    children: [
                      for (final e in evidence)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFCF3),
                            border: Border.all(color: const Color(0xFFF2EBDD)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${e['item_name']} · ${e['field_label']}',
                                style: const TextStyle(
                                  color: ink,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${e['text']}',
                                style: const TextStyle(
                                  color: mutedInk,
                                  fontSize: 8,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              if (sources.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  '참고: ${sources.join(', ')}',
                  style: const TextStyle(color: mutedInk, fontSize: 8),
                ),
              ],
            ],
          ),
        ),
      ),
    ],
  );
}

class _ChatSuggestion extends StatelessWidget {
  const _ChatSuggestion({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 24,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: brandYellow,
        side: const BorderSide(color: brandYellow, width: 0.8),
        padding: const EdgeInsets.symmetric(horizontal: 9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    ),
  );
}

class PermitListPage extends StatelessWidget {
  const PermitListPage({super.key});
  @override
  Widget build(BuildContext context) => SimpleSubPage(
    title: '전자 구매 허가서',
    child: Column(
      children: const [
        PermitCard(
          title: '타이레놀정 500mg',
          status: '사용 가능',
          active: true,
          quantity: '10정 / 1갑',
          period: '2025.01.15 ~ 2025.07.15',
          pharmacy: '김약사 (늘푸른약국)',
        ),
        PermitCard(
          title: '탁센 연질캡슐',
          status: '기간 만료',
          quantity: '10캡슐 / 1갑',
          period: '2024.08.01 ~ 2025.02.01',
          pharmacy: '박진형 약사 (온누리약국)',
        ),
        PermitCard(
          title: '베아제정 소화제',
          status: '기간 만료',
          quantity: '10정 / 1갑',
          period: '2024.06.10 ~ 2024.12.10',
          pharmacy: '이수진 약사 (메디컬약국)',
        ),
      ],
    ),
  );
}

class PermitCard extends StatelessWidget {
  const PermitCard({
    required this.title,
    required this.status,
    required this.quantity,
    required this.period,
    required this.pharmacy,
    this.active = false,
    super.key,
  });
  final String title, status, quantity, period, pharmacy;
  final bool active;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: active ? const Color(0xFFFFD866) : const Color(0xFFF0ECE9),
        width: active ? 1.2 : 0.8,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x10000000),
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.assignment_outlined,
              color: active ? brandYellow : mutedInk,
              size: 12,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: ink,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFFE8F8ED)
                    : const Color(0xFFF0EFED),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: active ? const Color(0xFF1CAA62) : mutedInk,
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const Divider(height: 14, thickness: 0.6),
        DetailLine(label: '수량', value: quantity),
        DetailLine(label: '유효기간', value: period),
        DetailLine(label: '발급 약사', value: pharmacy),
      ],
    ),
  );
}

class DetailLine extends StatelessWidget {
  const DetailLine({required this.label, required this.value, super.key});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(
            label,
            style: const TextStyle(color: mutedInk, fontSize: 8, height: 1.1),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: ink, fontSize: 8, height: 1.1),
          ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('신청할 약품을 선택해주세요.')),
      );
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
                              Icon(Icons.grid_view, color: brandYellow, size: 16),
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
                        borderSide: const BorderSide(
                          color: Color(0xFFECE7E3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFECE7E3),
                        ),
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
              child: PrimaryButton(
                label: '신청하기',
                onPressed: _submitRequest,
              ),
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

class SimpleSubPage extends StatelessWidget {
  const SimpleSubPage({
    required this.title,
    required this.child,
    this.bottom,
    super.key,
  });
  final String title;
  final Widget child;
  final Widget? bottom;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          const AppStatusBar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.chevron_left, size: 30),
                      ),
                      Expanded(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: ink,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Expanded(child: SingleChildScrollView(child: child)),
                  if (bottom != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: bottom!,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  final _searchController = TextEditingController();
  int _selectedTab = 0;
  int _selectedCategory = 0;
  bool _searchOpen = false;

  static const _products = [
    _StoreProduct('타이레놀 ER 정', '일반 상비', '3,000원', _ProductKind.tylenol),
    _StoreProduct(
      '판콜 에이 내복액',
      '의약품 🔒',
      '2,600원',
      _ProductKind.cough,
      locked: true,
    ),
    _StoreProduct(
      '훼스탈 플러스 정',
      '소화제',
      '3,500원',
      _ProductKind.digestive,
      soldOut: true,
    ),
    _StoreProduct('생리식염수 세척용', '일반 위생', '1,500원', _ProductKind.saline),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_StoreProduct> get _visibleProducts {
    Iterable<_StoreProduct> products = _products;
    if (_selectedTab == 1) {
      products = products.where(
        (product) => _selectedCategory == 0
            ? product.category != '의약품 🔒'
            : product.category == '의약품 🔒',
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
    required this.searchOpen,
    required this.searchController,
    required this.onBack,
    required this.onSearchToggle,
    required this.onSearchChanged,
  });

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
              : const Text(
                  '3호관 2층 자판기',
                  textAlign: TextAlign.center,
                  style: TextStyle(
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

enum _ProductKind { tylenol, cough, digestive, saline }

class _StoreProduct {
  const _StoreProduct(
    this.name,
    this.category,
    this.price,
    this.kind, {
    this.locked = false,
    this.soldOut = false,
  });

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

class AuthField extends StatelessWidget {
  const AuthField({
    required this.hint,
    this.keyboardType,
    this.obscureText = false,
    super.key,
  });

  final String hint;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) => TextField(
    keyboardType: keyboardType,
    obscureText: obscureText,
    decoration: InputDecoration(hintText: hint),
  );
}

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.title,
    required this.subtitle,
    required this.fields,
    required this.actionLabel,
    required this.bottomLabel,
    required this.bottomActionLabel,
    required this.onBottomAction,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<Widget> fields;
  final String actionLabel;
  final String bottomLabel;
  final String bottomActionLabel;
  final VoidCallback onBottomAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 44, 28, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const BrandMark(size: 32),
                  const SizedBox(height: 48),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: ink,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: mutedInk, fontSize: 14),
                  ),
                  const SizedBox(height: 34),
                  ...fields.expand(
                    (field) => [field, const SizedBox(height: 12)],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 56,
                    child: FilledButton(
                      onPressed: () {},
                      style: FilledButton.styleFrom(
                        backgroundColor: brandYellow,
                        foregroundColor: ink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: Text(actionLabel),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        bottomLabel,
                        style: const TextStyle(color: mutedInk, fontSize: 13),
                      ),
                      TextButton(
                        onPressed: onBottomAction,
                        style: TextButton.styleFrom(
                          foregroundColor: ink,
                          padding: const EdgeInsets.only(left: 5),
                        ),
                        child: Text(
                          bottomActionLabel,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
