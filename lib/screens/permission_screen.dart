import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'login_page.dart';

const _background = Color(0xFFF5F5F3);
const _overlay = Color(0x803E2723);
const _darkBrown = Color(0xFF3E2723);
const _labelBrown = Color(0xFF7D6D6A);
const _hintBrown = Color(0xFFBCAAA4);
const _dividerColor = Color(0xFFEFEBE9);
const _iconBackground = Color(0xFFFFFDE7);

class PermissionScreen extends StatelessWidget {
  const PermissionScreen({this.onAllow, super.key});

  final VoidCallback? onAllow;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF9E908C),
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
    child: Scaffold(
      backgroundColor: _background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: _overlay),
          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [_PermissionBottomSheet(onAllow: onAllow)],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PermissionBottomSheet extends StatelessWidget {
  const _PermissionBottomSheet({required this.onAllow});

  final VoidCallback? onAllow;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      boxShadow: [
        BoxShadow(
          color: Color(0x1A000000),
          offset: Offset(0, -8),
          blurRadius: 12,
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '앱 이용 권한 안내',
              style: TextStyle(
                color: _darkBrown,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '모약 서비스를 편리하게 이용하기 위해 다음 권한 허용이 필요합니다.',
              style: TextStyle(color: _labelBrown, fontSize: 14, height: 1),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const Divider(height: 1, thickness: 1, color: _dividerColor),
        const SizedBox(height: 28),
        const Column(
          children: [
            _PermissionRow(
              iconAsset: 'assets/figma/camera_permission.svg',
              title: '카메라 (선택)',
              description: '약품 바코드 인식 및 QR코드 매칭 시 사용됩니다.',
            ),
            SizedBox(height: 20),
            _PermissionRow(
              iconAsset: 'assets/figma/location_permission.svg',
              title: '위치 정보 (선택)',
              description: '가장 가까운 모약 자판기 위치를 조회할 때 필요합니다.',
            ),
            SizedBox(height: 20),
            _PermissionRow(
              iconAsset: 'assets/figma/microphone_permission.svg',
              title: '마이크 (선택)',
              description: '약사와 화상 상담할 때 사용됩니다.',
            ),
          ],
        ),
        const SizedBox(height: 28),
        Column(
          children: [
            const Text(
              '권한은 해당 기능을 사용할 때 요청합니다.\n허용하지 않아도 다른 기능을 이용할 수 있어요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _hintBrown, fontSize: 12, height: 1),
            ),
            const SizedBox(height: 12),
            LoginPrimaryButton(
              label: '계속하기',
              onPressed: onAllow ?? () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ],
    ),
  );
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.iconAsset,
    required this.title,
    required this.description,
  });

  final String iconAsset;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: _iconBackground,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: SvgPicture.asset(iconAsset, width: 20, height: 20),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: _darkBrown,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                color: _labelBrown,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
