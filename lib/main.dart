import 'machine_map_page.dart';
import 'package:flutter/material.dart';

const pageBackground = Color(0xFFFFFBE8);
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
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const LoginPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: BrandMark(size: 52)));
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

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 34, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '로그인',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 15),
              const BrandMark(size: 68),
              const SizedBox(height: 30),
              const LabeledField(label: '아이디', hint: '아이디를 입력해주세요'),
              const SizedBox(height: 12),
              const LabeledField(
                label: '비밀번호',
                hint: '비밀번호를 입력해주세요',
                obscureText: true,
              ),
              const SizedBox(height: 33),
              PrimaryButton(
                label: '로그인',
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(builder: (_) => const AppShell()),
                ),
              ),
              const SizedBox(height: 21),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SignupPage(),
                      ),
                    ),
                    child: const Text('회원가입'),
                  ),
                  const Text('|', style: TextStyle(color: Color(0xFFB9AAA4))),
                  TextButton(onPressed: () {}, child: const Text('ID·PW 찾기')),
                ],
              ),
              const SizedBox(height: 11),
              const SocialDivider(),
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SocialButton(label: 'N', color: Color(0xFF00C73C)),
                  SizedBox(width: 17),
                  SocialButton(
                    label: '톡',
                    color: Color(0xFFFFE000),
                    textColor: ink,
                  ),
                  SizedBox(width: 17),
                  SocialButton(
                    label: '⊗',
                    color: Colors.white,
                    textColor: ink,
                    outlined: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
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

  void selectTab(int index) => setState(() => selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        onOpenStore: () => Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => const StorePage())),
      ),
      selectedIndex == 1 ? const MapPage() : const SizedBox.shrink(),
      const QrPage(),
      const ChatPage(),
      Mypage(
        onOpenPermit: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const PermitListPage())),
        onOpenInventory: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const InventoryRequestPage()),
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
  Widget build(BuildContext context) => BottomNavigationBar(
    currentIndex: selectedIndex,
    onTap: onSelected,
    type: BottomNavigationBarType.fixed,
    backgroundColor: Colors.white,
    selectedItemColor: brandYellow,
    unselectedItemColor: const Color(0xFF8D7F79),
    selectedFontSize: 11,
    unselectedFontSize: 11,
    items: const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: '메인',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.location_on_outlined),
        activeIcon: Icon(Icons.location_on),
        label: '지도',
      ),
      BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'QR스캔'),
      BottomNavigationBarItem(
        icon: Icon(Icons.chat_bubble_outline),
        activeIcon: Icon(Icons.chat_bubble),
        label: '모약이',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: '마이',
      ),
    ],
  );
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
  Widget build(BuildContext context) => const MachineMapPage();
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
        const Row(
          children: [
            CircleAvatar(
              backgroundColor: Color(0xFFE9DCC8),
              radius: 28,
              child: Icon(Icons.person, color: Colors.white),
            ),
            SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '홍길동',
                  style: TextStyle(
                    color: ink,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'gildong.hong@gmail.com',
                  style: TextStyle(color: mutedInk, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),
        const ListTile(
          leading: Icon(Icons.credit_card, color: brandYellow),
          title: Text(
            '간편 결제 카드 등록됨',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            '국민카드 **** 1294 (자판기 다이렉트 결제)',
            style: TextStyle(fontSize: 11),
          ),
          shape: RoundedRectangleBorder(
            side: BorderSide(color: brandYellow),
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: ActionCard(
                icon: Icons.receipt_long,
                title: '전자 구매 허가서',
                onTap: onOpenPermit,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ActionCard(
                icon: Icons.shopping_cart_outlined,
                title: '재고 신청하기',
                onTap: onOpenInventory,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        ...['공지사항 및 서비스 안내', '고객 지원', '앱 설정', '계정 보안', '로그아웃'].map(
          (label) => ListTile(
            title: Text(
              label,
              style: TextStyle(
                color: label == '로그아웃' ? Colors.red : ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: mutedInk),
            contentPadding: EdgeInsets.zero,
            dense: true,
            shape: const Border(bottom: BorderSide(color: Color(0xFFEDE7E4))),
          ),
        ),
      ],
    ),
  );
}

class ActionCard extends StatelessWidget {
  const ActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
    super.key,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: brandYellow),
          Text(
            title,
            style: const TextStyle(color: ink, fontWeight: FontWeight.w700),
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
    child: Padding(padding: padding, child: child),
  );
}

class QrPage extends StatelessWidget {
  const QrPage({super.key});
  @override
  Widget build(BuildContext context) => Container(
    color: Colors.black,
    child: SafeArea(
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.chevron_left,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const Expanded(
                child: Text(
                  'QR 스캔',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 48),
          const Text(
            'QR 코드를 스캔하세요',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '자판기 화면의 QR 코드를 비추면 연결됩니다',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 60),
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 4),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Center(
              child: Icon(Icons.qr_code_2, color: Colors.white, size: 165),
            ),
          ),
        ],
      ),
    ),
  );
}

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});
  @override
  Widget build(BuildContext context) => AppPage(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.chevron_left, size: 30),
            ),
            const CircleAvatar(
              backgroundColor: Color(0xFFFFF0B4),
              child: Icon(Icons.medical_services_outlined, color: brandYellow),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '모약이',
                  style: TextStyle(
                    color: ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '● 상담 가능',
                  style: TextStyle(color: Color(0xFF18B55B), fontSize: 11),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.phone_outlined, color: mutedInk),
            const SizedBox(width: 15),
            const Icon(Icons.search, color: mutedInk),
          ],
        ),
        const Divider(),
        const SizedBox(height: 18),
        const Text(
          '오늘',
          textAlign: TextAlign.center,
          style: TextStyle(color: mutedInk, fontSize: 11),
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFFFF0B4),
              child: Icon(Icons.medical_services_outlined, color: brandYellow),
            ),
            const SizedBox(width: 10),
            Container(
              constraints: const BoxConstraints(maxWidth: 260),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                '안녕하세요! 자판기 건강 헬퍼 모약이입니다. 무엇을 도와드릴까요?',
                style: TextStyle(color: ink, height: 1.45),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const SizedBox(width: 64),
            OutlinedButton(onPressed: () {}, child: const Text('약품 정보')),
            const SizedBox(width: 8),
            OutlinedButton(onPressed: () {}, child: const Text('상담하기')),
          ],
        ),
        const Spacer(),
        Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.add, color: mutedInk),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: '메시지를 입력하세요...',
                  fillColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const CircleAvatar(
              backgroundColor: brandYellow,
              child: Icon(Icons.arrow_upward, color: Colors.white),
            ),
          ],
        ),
      ],
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
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: active ? brandYellow : Colors.transparent,
        width: active ? 1.5 : 0,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x10000000),
          blurRadius: 10,
          offset: Offset(0, 4),
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
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFFE7F8EE)
                    : const Color(0xFFEDE9E7),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: active ? const Color(0xFF1CAA62) : mutedInk,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const Divider(height: 24),
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
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(color: mutedInk, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(color: ink, fontSize: 12)),
        ),
      ],
    ),
  );
}

class InventoryRequestPage extends StatefulWidget {
  const InventoryRequestPage({super.key});
  @override
  State<InventoryRequestPage> createState() => _InventoryRequestPageState();
}

class _InventoryRequestPageState extends State<InventoryRequestPage> {
  final selected = <String>{};
  @override
  Widget build(BuildContext context) => SimpleSubPage(
    title: '재고 신청',
    bottom: PrimaryButton(label: '신청하기', onPressed: () {}),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '자판기 선택',
          style: TextStyle(color: ink, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            children: [
              Icon(Icons.grid_view, color: brandYellow),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '3호관 2층 자판기',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Icon(Icons.keyboard_arrow_down, color: mutedInk),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          '신청할 약품 선택',
          style: TextStyle(color: ink, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        ...['어린이 부루펜시럽', '겔포스엠 현탁액', '이지엔6 프로 연질캡슐'].map(
          (medicine) => CheckboxListTile(
            value: selected.contains(medicine),
            onChanged: (value) => setState(
              () => value == true
                  ? selected.add(medicine)
                  : selected.remove(medicine),
            ),
            title: Text(
              medicine,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text(
              '남은 수량 0개',
              style: TextStyle(color: Colors.red, fontSize: 11),
            ),
            controlAffinity: ListTileControlAffinity.trailing,
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            dense: true,
          ),
        ),
      ],
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
  );
}

class StorePage extends StatelessWidget {
  const StorePage({super.key});
  @override
  Widget build(BuildContext context) => SimpleSubPage(
    title: '3호관 2층 자판기',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Expanded(
              child: Center(
                child: Text(
                  '빠른 구매',
                  style: TextStyle(
                    color: brandYellow,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text('카테고리', style: TextStyle(color: mutedInk)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: ['일반 상비품', '여성용품', '의약품 🔒']
              .map(
                (label) => Chip(
                  label: Text(label),
                  backgroundColor: label == '일반 상비품'
                      ? const Color(0xFFFFD866)
                      : Colors.white,
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: .75,
          children: const [
            ProductCard(
              title: '타이레놀 ER 정',
              category: '일반 상비',
              price: '3,000원',
              icon: Icons.medication_outlined,
            ),
            ProductCard(
              title: '판콜 에이 내복액',
              category: '의약품 🔒',
              price: '2,600원',
              icon: Icons.local_pharmacy_outlined,
            ),
            ProductCard(
              title: '훼스탈 플러스 정',
              category: '소화제',
              price: '3,500원',
              icon: Icons.medication,
            ),
            ProductCard(
              title: '생리식염수 세척용',
              category: '일반 위생',
              price: '1,500원',
              icon: Icons.water_drop_outlined,
            ),
          ],
        ),
      ],
    ),
  );
}

class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.title,
    required this.category,
    required this.price,
    required this.icon,
    super.key,
  });
  final String title, category, price;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Center(
            child: Icon(icon, size: 62, color: const Color(0xFFD3CEC7)),
          ),
        ),
        Text(category, style: const TextStyle(color: mutedInk, fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(color: ink, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 7),
        Text(
          price,
          style: const TextStyle(
            color: brandYellow,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
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
