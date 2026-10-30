import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../data/models.dart';
import '../utils/format.dart';
import '../widgets/sub_page_scaffold.dart';
import '../config/app_config.dart';
import '../widgets/preview_list_controls.dart';

/// 전자 구매 허가서 목록: 약사 상담으로 발급받은 허가서와 사용 상태.
class PermitListScreen extends StatefulWidget {
  const PermitListScreen({
    this.bottomNavigationBar,
    this.loadRecords,
    super.key,
  });

  final Widget? bottomNavigationBar;
  final Future<List<PermitRecord>> Function()? loadRecords;

  @override
  State<PermitListScreen> createState() => _PermitListScreenState();
}

class _PermitListScreenState extends State<PermitListScreen> {
  PreviewListState _previewState = PreviewListState.populated;
  late Future<List<PermitRecord>> _permits = _load();
  Future<List<PermitRecord>> _load() async {
    if (AppConfig.preview.value &&
        _previewState != PreviewListState.populated) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (_previewState == PreviewListState.error) {
        throw StateError('조회 실패 미리보기');
      }
      return [];
    }
    return (widget.loadRecords ?? fetchPermits)();
  }

  @override
  Widget build(BuildContext context) => SubPageScaffold(
    title: '전자 구매 허가서',
    bottomNavigationBar: widget.bottomNavigationBar,
    child: Column(
      children: [
        if (AppConfig.preview.value)
          PreviewListControls(
            value: _previewState,
            onChanged: (value) => setState(() {
              _previewState = value;
              _permits = _load();
            }),
          ),
        Expanded(
          child: FutureBuilder<List<PermitRecord>>(
            future: _permits,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Column(
                  children: [
                    const SubPageMessage('구매 허가서를 불러오지 못했어요.', error: true),
                    TextButton(
                      onPressed: () => setState(() {
                        _permits = _load();
                      }),
                      child: const Text('다시 시도'),
                    ),
                  ],
                );
              }
              final permits = snapshot.data;
              if (permits == null) return const SubPageMessage('불러오는 중...');
              if (permits.isEmpty) {
                return const SubPageMessage(
                  '아직 발급된 전자 구매 허가서가 없습니다.\n약사 상담을 통해 승인을 받으면 여기에 표시돼요.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: permits.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (context, index) =>
                    _PermitCard(permit: permits[index]),
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _PermitCard extends StatelessWidget {
  const _PermitCard({required this.permit});

  final PermitRecord permit;

  String get _statusLabel => switch (permit.status) {
    PermitStatus.available => '사용 가능',
    PermitStatus.expired => '기간 만료',
    PermitStatus.dispensed => '수령 완료',
    PermitStatus.cancelled => '취소됨',
    PermitStatus.unknown => '상태 확인 필요',
  };

  @override
  Widget build(BuildContext context) {
    final active = permit.status == PermitStatus.available;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? const Color(0xFFFFD970) : const Color(0xFFEFEBE9),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A3E2723),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.fact_check_outlined,
                color: active ? const Color(0xFFFFB300) : subPageMuted,
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  permit.drugName,
                  style: const TextStyle(
                    color: subPageInk,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFFE8F8EE)
                      : const Color(0xFFEFEBE9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    color: active ? const Color(0xFF03C75A) : subPageMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: Color(0xFFEFEBE9)),
          ),
          _MetaRow(
            label: '유효기간',
            value:
                '${formatDate(permit.issuedAt)} ~ ${formatDate(permit.expiresAt)}',
          ),
          const SizedBox(height: 6),
          _MetaRow(label: '발급 약사', value: permit.pharmacist),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 64,
        child: Text(
          label,
          style: const TextStyle(color: subPageMuted, fontSize: 13),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(
            color: subPageInk,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ],
  );
}
