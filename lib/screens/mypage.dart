import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/app_session.dart';
import '../widgets/app_status_bar.dart';
import '../widgets/feature_notice.dart';

// 백엔드 HTML `app/mypage/style.css` 기준 값.
const _background = Color(0xFFF5F5F3);
const _darkBrown = Color(0xFF3E2723);
const _mutedBrown = Color(0xFF7D6D6A);
const _border = Color(0xFFEFEBE9);
const _cream = Color(0xFFFFFDE7);
const _logoutRed = Color(0xFFFF3B30);

class Mypage extends StatelessWidget {
  const Mypage({
    required this.onOpenConsultHistory,
    required this.onOpenPermit,
    required this.onOpenInventory,
    this.onLogout,
    super.key,
  });

  final VoidCallback onOpenConsultHistory;
  final VoidCallback onOpenPermit;
  final VoidCallback onOpenInventory;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    final userId = AppSession.instance.userId;
    return ColoredBox(
      color: _background,
      child: SafeArea(
        child: Column(
          children: [
            const AppStatusBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProfileHeader(
                      userLabel: userId == null
                          ? '로그인 정보 없음'
                          : 'ID ${userId.length > 8 ? '${userId.substring(0, 8)}...' : userId}',
                      onTapPayment: () =>
                          showFeatureNotice(context, '결제는 자판기에서 진행합니다.'),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ActionCard(
                                iconAsset: 'assets/figma/mypage_file_check.svg',
                                iconBackground: _cream,
                                title: '전자 구매 허가서',
                                description: '약사 발급 처방장 열람',
                                onTap: onOpenPermit,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ActionCard(
                                iconAsset:
                                    'assets/figma/mypage_shopping_cart.svg',
                                iconBackground: const Color(0xFFE8F8EE),
                                title: '재고 신청하기',
                                description: '없는 약품 수급 요청',
                                onTap: () => showFeatureNotice(
                                  context,
                                  '재고 신청은 준비 중이에요.',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DecoratedBox(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border.symmetric(
                          horizontal: BorderSide(color: _border),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            _MypageMenuItem(
                              label: '내 상담 내역 (처방·상담 요약)',
                              onTap: onOpenConsultHistory,
                            ),
                            const _MypageMenuItem(label: '공지사항 및 서비스 안내'),
                            const _MypageMenuItem(label: '고객 지원'),
                            const _MypageMenuItem(label: '앱 설정'),
                            const _MypageMenuItem(label: '계정 보안'),
                            _MypageMenuItem(
                              label: '로그아웃',
                              destructive: true,
                              showDivider: false,
                              onTap: onLogout,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.userLabel, required this.onTapPayment});

  final String userLabel;
  final VoidCallback onTapPayment;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: _border)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFE9DCC8),
              radius: 32,
              child: Icon(Icons.person, color: Colors.white, size: 38),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '게스트 사용자',
                    style: TextStyle(
                      color: _darkBrown,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userLabel,
                    style: const TextStyle(color: _mutedBrown, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(height: 1, thickness: 1, color: _border),
        const SizedBox(height: 16),
        Material(
          color: _cream,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Color(0xFFFFD970)),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTapPayment,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/figma/mypage_credit_card.svg',
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '등록된 결제 수단이 없어요',
                          style: TextStyle(
                            color: _darkBrown,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '결제는 자판기에서 진행해주세요.',
                          style: TextStyle(color: _mutedBrown, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _MypageMenuItem extends StatelessWidget {
  const _MypageMenuItem({
    required this.label,
    this.destructive = false,
    this.showDivider = true,
    this.onTap,
  });

  final String label;
  final bool destructive;
  final bool showDivider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap ?? () => showFeatureNotice(context),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: showDivider
          ? const BoxDecoration(
              border: Border(bottom: BorderSide(color: _border)),
            )
          : null,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: destructive ? _logoutRed : _darkBrown,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, color: _mutedBrown, size: 16),
        ],
      ),
    ),
  );
}

class ActionCard extends StatelessWidget {
  const ActionCard({
    required this.iconAsset,
    required this.iconBackground,
    required this.title,
    required this.onTap,
    this.description = '',
    super.key,
  });
  final String iconAsset;
  final Color iconBackground;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: _border),
      borderRadius: BorderRadius.circular(16),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBackground,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(iconAsset, width: 20, height: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: _darkBrown,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(color: _mutedBrown, fontSize: 11),
            ),
          ],
        ),
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
          child: SingleChildScrollView(
            child: Padding(padding: padding, child: child),
          ),
        ),
      ],
    ),
  );
}
