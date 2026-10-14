import 'package:flutter/material.dart';

import 'app_status_bar.dart';

/// 약사상담·챗봇 화면의 초록 계열 팔레트 (백엔드 HTML pharmacist-waiting / chatbot).
const consultGreen = Color(0xFF176B5B);
const consultDeepGreen = Color(0xFF105348);
const consultMint = Color(0xFFDDEEE8);
const consultCream = Color(0xFFF6F2E9);
const consultHeaderCream = Color(0xFFFFFCF6);
const consultLine = Color(0xFFE4DDD2);
const consultBeige = Color(0xFFEEE8DD);
const consultBrown = Color(0xFF342521);
const consultMutedBrown = Color(0xFF776A64);

/// 크림색 상단 헤더: 초록 알약 마크 + 제목/부제 + QR 스캔 버튼.
class ConsultCreamHeader extends StatelessWidget {
  const ConsultCreamHeader({
    required this.title,
    required this.subtitle,
    required this.onScanQr,
    super.key,
  });

  final String title;
  final String subtitle;
  final VoidCallback onScanQr;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: consultHeaderCream,
      border: Border(bottom: BorderSide(color: consultLine)),
    ),
    child: SafeArea(
      bottom: false,
      child: Column(
        children: [
          const AppStatusBar(color: consultBrown),
          SizedBox(
            height: 60,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 16, 0),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: consultGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.medication_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: consultBrown,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: consultMutedBrown,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  QrScanPill(onTap: onScanQr),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// 헤더 오른쪽 "QR 스캔" 알약 버튼. 어두운 헤더에서는 [dark]를 켠다.
class QrScanPill extends StatelessWidget {
  const QrScanPill({required this.onTap, this.dark = false, super.key});

  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      boxShadow: dark
          ? null
          : const [
              BoxShadow(
                color: Color(0x1449382F),
                blurRadius: 18,
                offset: Offset(0, 6),
              ),
            ],
    ),
    child: Material(
      color: dark ? const Color(0x14FFFFFF) : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(color: dark ? const Color(0x29FFFFFF) : consultLine),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: SizedBox(
          height: 40,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  color: dark ? Colors.white : consultGreen,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'QR 스캔',
                  style: TextStyle(
                    color: dark ? Colors.white : consultBrown,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// 상담 요약 본문. "■ 항목" 줄은 굵은 소제목, "※" 줄은 작은 안내 문구로 보여준다.
class ConsultSummaryBody extends StatelessWidget {
  const ConsultSummaryBody({required this.summary, super.key});

  final String summary;

  static const _heading = Color(0xFF593D0D);
  static const _body = Color(0xFF3E2723);
  static const _note = Color(0xFF7D6D6A);

  @override
  Widget build(BuildContext context) {
    final lines = summary
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          if (line.startsWith('■'))
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 3),
              child: Text(
                line.substring(1).trim(),
                style: const TextStyle(
                  color: _heading,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else if (line.startsWith('※'))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                line,
                style: const TextStyle(color: _note, fontSize: 11, height: 1.5),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                line,
                style: const TextStyle(
                  color: _body,
                  fontSize: 13,
                  height: 1.55,
                ),
              ),
            ),
      ],
    );
  }
}
