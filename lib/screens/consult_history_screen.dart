import 'package:flutter/material.dart';

import '../data/demo_data.dart';
import '../data/models.dart';
import '../utils/format.dart';
import '../widgets/consult_header.dart';
import '../widgets/sub_page_scaffold.dart';
import '../config/app_config.dart';
import '../widgets/preview_list_controls.dart';

/// 내 상담 내역: 지난 약사 상담의 결과(처방약·거절 사유)와 상담 요약을 다시 보는 화면.
class ConsultHistoryScreen extends StatefulWidget {
  const ConsultHistoryScreen({
    required this.onOpenDetail,
    this.bottomNavigationBar,
    this.loadRecords,
    super.key,
  });

  final ValueChanged<ConsultRecord> onOpenDetail;
  final Widget? bottomNavigationBar;
  final Future<List<ConsultRecord>> Function()? loadRecords;

  @override
  State<ConsultHistoryScreen> createState() => _ConsultHistoryScreenState();
}

class _ConsultHistoryScreenState extends State<ConsultHistoryScreen> {
  PreviewListState _previewState = PreviewListState.populated;
  late Future<List<ConsultRecord>> _history = _load();
  Future<List<ConsultRecord>> _load() async {
    if (AppConfig.preview.value &&
        _previewState != PreviewListState.populated) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (_previewState == PreviewListState.error) {
        throw StateError('조회 실패 미리보기');
      }
      return [];
    }
    return (widget.loadRecords ?? fetchConsultHistory)();
  }

  @override
  Widget build(BuildContext context) => SubPageScaffold(
    title: '내 상담 내역',
    bottomNavigationBar: widget.bottomNavigationBar,
    child: Column(
      children: [
        if (AppConfig.preview.value)
          PreviewListControls(
            value: _previewState,
            onChanged: (value) => setState(() {
              _previewState = value;
              _history = _load();
            }),
          ),
        Expanded(
          child: FutureBuilder<List<ConsultRecord>>(
            future: _history,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Column(
                  children: [
                    const SubPageMessage('상담 내역을 불러오지 못했어요.', error: true),
                    TextButton(
                      onPressed: () => setState(() {
                        _history = _load();
                      }),
                      child: const Text('다시 시도'),
                    ),
                  ],
                );
              }
              final records = snapshot.data;
              if (records == null) return const SubPageMessage('불러오는 중...');
              if (records.isEmpty) {
                return const SubPageMessage(
                  '아직 약사 상담 내역이 없어요.\n아래 가운데 "상담하기"를 누르면 약사와 바로 상담할 수 있어요.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: records.length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (context, index) => _HistoryCard(
                  record: records[index],
                  onOpenDetail: () => widget.onOpenDetail(records[index]),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.record, required this.onOpenDetail});

  final ConsultRecord record;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final summary = record.summary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEBE9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A3E2723),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${formatDate(record.createdAt)} ${formatTime(record.createdAt)}',
                  style: const TextStyle(
                    color: subPageMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (record.endedAt != null &&
                  record.status == ConsultStatus.pending)
                const Text('상담 종료')
              else
                _StatusPill(status: record.status),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            record.direct ? '바로 약사 상담' : '모약이 챗봇 상담 후 약사 상담',
            style: const TextStyle(
              color: subPageInk,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _ResultBox(record: record),
          if (summary != null) ...[
            const SizedBox(height: 10),
            _SummaryToggle(summary: summary),
          ],
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onOpenDetail,
              style: TextButton.styleFrom(
                foregroundColor: consultGreen,
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('자세히 보기 ›'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final ConsultStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, background, foreground) = switch (status) {
      ConsultStatus.approved => (
        '처방 완료',
        const Color(0xFFDDEEE8),
        const Color(0xFF105348),
      ),
      ConsultStatus.rejected => (
        '처방 불가',
        const Color(0xFFFDECEA),
        const Color(0xFFC0392B),
      ),
      ConsultStatus.pending => (
        '상담 진행 중',
        const Color(0xFFFFF8E1),
        const Color(0xFF8B6914),
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ResultBox extends StatelessWidget {
  const _ResultBox({required this.record});

  final ConsultRecord record;

  @override
  Widget build(BuildContext context) {
    final (
      label,
      value,
      note,
      background,
      foreground,
    ) = switch (record.status) {
      ConsultStatus.approved => (
        '처방약',
        record.approvedDrugName ?? '-',
        '가까운 자판기에서 QR을 스캔하면 받을 수 있어요',
        const Color(0xFFF1F8F5),
        const Color(0xFF105348),
      ),
      ConsultStatus.rejected => (
        '약사 안내',
        record.decisionReason ?? '사유가 따로 전달되지 않았어요',
        null,
        const Color(0xFFFDF3F2),
        const Color(0xFF8E2B20),
      ),
      ConsultStatus.pending => (
        '진행 상황',
        record.endedAt != null ? '상담이 종료되었어요' : '약사 상담을 기다리고 있어요',
        null,
        const Color(0xFFFFFDE7),
        const Color(0xFF593D0D),
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: foreground,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 4),
            Text(note, style: TextStyle(color: foreground, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

/// `<details>` "📝 상담 요약 보기" — 눌러서 펼치는 상담 요약.
class _SummaryToggle extends StatefulWidget {
  const _SummaryToggle({required this.summary});

  final String summary;

  @override
  State<_SummaryToggle> createState() => _SummaryToggleState();
}

class _SummaryToggleState extends State<_SummaryToggle> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFFFFFDF5),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFF1E3B8)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  _open ? Icons.arrow_drop_down : Icons.arrow_right,
                  color: const Color(0xFF593D0D),
                  size: 20,
                ),
                const Text(
                  '📝 상담 요약 보기',
                  style: TextStyle(
                    color: Color(0xFF593D0D),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_open)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: ConsultSummaryBody(summary: widget.summary),
          ),
      ],
    ),
  );
}
