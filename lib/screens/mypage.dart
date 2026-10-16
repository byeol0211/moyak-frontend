import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_status_bar.dart';
import '../widgets/feature_notice.dart';

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
                        '게스트 사용자',
                        style: TextStyle(
                          color: ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 7),
                      SizedBox.shrink(),
                    ],
                  ),
                  SizedBox(height: 3),
                  Text(
                    '로그인 기능 준비 중',
                    style: TextStyle(color: mutedInk, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        InkWell(
          onTap: () => showFeatureNotice(context, '결제는 자판기에서 진행합니다.'),
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
                        '등록된 결제수단 없음',
                        style: TextStyle(
                          color: ink,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        '결제는 자판기에서 진행해주세요.',
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
                description: '준비 중',
                onTap: () => showFeatureNotice(context, '재고 신청은 준비 중이에요.'),
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
          (label) => _MypageMenuItem(
            label: label,
            destructive: label == '로그아웃',
            onTap: label == '로그아웃' ? onLogout : null,
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
    this.onTap,
  });

  final String label;
  final bool destructive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 31,
    child: InkWell(
      onTap: onTap ?? () => showFeatureNotice(context),
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
          child: SingleChildScrollView(
            child: Padding(padding: padding, child: child),
          ),
        ),
      ],
    ),
  );
}
