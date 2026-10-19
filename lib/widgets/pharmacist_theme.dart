import 'package:flutter/material.dart';

import 'app_status_bar.dart';

/// 약사 연결 대기·화상 상담 입장 화면의 색 (키오스크 계열 노랑·갈색 + 상담 초록).
const pharmBrown = Color(0xFF593D0D);
const pharmMuted = Color(0xFF827669);
const pharmYellow = Color(0xFFFFD54F);
const pharmPageBg = Color(0xFFFFFDE7);
const pharmHeaderBg = Color(0xFFFFFEF7);
const pharmGreen = Color(0xFF267D68);
const pharmMint = Color(0xFFE5F2EC);
const pharmCardBorder = Color(0xFFF3F1EE);
const pharmWhiteCard = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.all(Radius.circular(24)),
  border: Border.fromBorderSide(BorderSide(color: pharmCardBorder)),
  boxShadow: [
    BoxShadow(color: Color(0x0F593D0D), blurRadius: 16, offset: Offset(0, 6)),
  ],
);

/// 크림색 헤더: 왼쪽은 노란 알약 마크(또는 [onBack]이 있으면 뒤로 버튼),
/// 가운데 제목·부제, 오른쪽 QR 스캔 버튼.
class PharmacistHeader extends StatelessWidget {
  const PharmacistHeader({
    required this.title,
    required this.subtitle,
    required this.onScanQr,
    this.onBack,
    super.key,
  });

  final String title;
  final String subtitle;
  final VoidCallback onScanQr;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: pharmHeaderBg,
    child: SafeArea(
      bottom: false,
      child: Column(
        children: [
          const AppStatusBar(color: pharmBrown),
          Padding(
            padding: EdgeInsets.fromLTRB(onBack == null ? 16 : 4, 10, 16, 14),
            child: Row(
              children: [
                if (onBack != null)
                  IconButton(
                    onPressed: onBack,
                    tooltip: '이전 화면',
                    icon: const Icon(
                      Icons.chevron_left,
                      color: pharmBrown,
                      size: 32,
                    ),
                  )
                else
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: pharmYellow,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.medication_outlined,
                      color: pharmBrown,
                      size: 24,
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: pharmBrown,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(color: pharmMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.white,
                  shape: const StadiumBorder(
                    side: BorderSide(color: Color(0xFFEBE7E2)),
                  ),
                  child: InkWell(
                    onTap: onScanQr,
                    customBorder: const StadiumBorder(),
                    child: const SizedBox(
                      height: 40,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.qr_code_scanner,
                              color: pharmBrown,
                              size: 20,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'QR 스캔',
                              style: TextStyle(
                                color: pharmBrown,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// 미리보기 모드 표시: 실제 상담과 연결되지 않은 화면임을 알린다.
class DemoModeChip extends StatelessWidget {
  const DemoModeChip({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF4C8),
      borderRadius: BorderRadius.circular(999),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.science_outlined, color: pharmBrown, size: 16),
        SizedBox(width: 6),
        Text(
          '디자인 시연 · 실제 상담 연결 없음',
          style: TextStyle(
            color: pharmBrown,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

/// 노란 큰 버튼 (예: "화상 상담 입장하기").
class PharmacistPrimaryButton extends StatelessWidget {
  const PharmacistPrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 60,
    child: FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: pharmYellow,
        foregroundColor: pharmBrown,
        disabledBackgroundColor: const Color(0xFFF3E7B8),
        disabledForegroundColor: pharmMuted,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      icon: Icon(icon, size: 24),
      label: Text(label),
    ),
  );
}
