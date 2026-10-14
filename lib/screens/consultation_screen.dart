import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/models.dart';
import '../utils/format.dart';
import '../widgets/app_status_bar.dart';
import '../widgets/consult_header.dart';
import 'video_consultation_page.dart';

const _lightMint = Color(0xFF65D6A8);
const _cardCream = Color(0xFFFFFCF6);
const _darkHeader = Color(0xFF1F2624);
const _darkBody = Color(0xFF18201E);
const _danger = Color(0xFFC94C43);
const _dangerBackground = Color(0xFFFBE7E4);
const _toggleOff = Color(0xFFC9C1B6);

/// 약사 상담 흐름: 연결 대기 → 화상 상담 입장.
///
/// - 하단 "상담하기"로 들어오면([direct]) 화상방이 준비되는 즉시 입장 화면으로 넘어간다.
/// - 챗봇의 "약사에게 바로 상담하기"로 들어오면 대기 화면에 머물며 입장 버튼을 보여준다.
/// - [record]를 주면 지난 상담의 결과(처방 완료·거절)를 보여준다.
class ConsultationScreen extends StatefulWidget {
  const ConsultationScreen({
    required this.onScanQr,
    required this.onOpenChatbot,
    this.direct = true,
    this.record,
    super.key,
  });

  final VoidCallback onScanQr;

  /// 상담 요청 취소, "챗봇으로 돌아가기" 후 이동할 곳.
  final VoidCallback onOpenChatbot;
  final bool direct;
  final ConsultRecord? record;

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  // 상담 API 연동 전이라 화상방 준비·약사 입장을 시간차로 흉내 낸다.
  static const _roomReadyDelay = Duration(seconds: 3);
  static const _pharmacistJoinDelay = Duration(seconds: 8);

  late final DateTime _requestedAt = widget.record?.createdAt ?? DateTime.now();
  late final ConsultStatus _status =
      widget.record?.status ?? ConsultStatus.pending;
  late bool _roomReady = widget.record != null;
  Duration _elapsed = Duration.zero;
  bool _pharmacistIn = false;
  bool _showingEntry = false;
  final _timers = <Timer>[];

  @override
  void initState() {
    super.initState();
    if (_status != ConsultStatus.pending) return;
    _tickClock();
    _timers.add(
      Timer.periodic(const Duration(seconds: 1), (_) => _tickClock()),
    );
    if (_roomReady) {
      _schedulePharmacistJoin();
    } else {
      _timers.add(
        Timer(_roomReadyDelay, () {
          if (!mounted) return;
          setState(() {
            _roomReady = true;
            _showingEntry = widget.direct;
          });
          _schedulePharmacistJoin();
        }),
      );
    }
  }

  void _tickClock() {
    if (!mounted) return;
    setState(() => _elapsed = DateTime.now().difference(_requestedAt));
  }

  void _schedulePharmacistJoin() => _timers.add(
    Timer(_pharmacistJoinDelay, () {
      if (mounted) setState(() => _pharmacistIn = true);
    }),
  );

  @override
  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    super.dispose();
  }

  Future<void> _confirmCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: const Text('상담 요청을 취소하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('아니요'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: _danger),
            child: const Text('요청 취소'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    for (final timer in _timers) {
      timer.cancel();
    }
    widget.onOpenChatbot();
  }

  @override
  Widget build(BuildContext context) => _showingEntry
      ? _VideoConsultationEntryView(
          onBack: () => setState(() => _showingEntry = false),
          onScanQr: widget.onScanQr,
        )
      : _PharmacistWaitingView(
          status: _status,
          record: widget.record,
          requestedAt: _requestedAt,
          elapsed: _elapsed,
          roomReady: _roomReady,
          pharmacistIn: _pharmacistIn,
          onScanQr: widget.onScanQr,
          onJoin: () => setState(() => _showingEntry = true),
          onCancel: _confirmCancel,
          onOpenChatbot: widget.onOpenChatbot,
        );
}

class _PharmacistWaitingView extends StatelessWidget {
  const _PharmacistWaitingView({
    required this.status,
    required this.record,
    required this.requestedAt,
    required this.elapsed,
    required this.roomReady,
    required this.pharmacistIn,
    required this.onScanQr,
    required this.onJoin,
    required this.onCancel,
    required this.onOpenChatbot,
  });

  final ConsultStatus status;
  final ConsultRecord? record;
  final DateTime requestedAt;
  final Duration elapsed;
  final bool roomReady;
  final bool pharmacistIn;
  final VoidCallback onScanQr;
  final VoidCallback onJoin;
  final VoidCallback onCancel;
  final VoidCallback onOpenChatbot;

  String get _elapsedLabel {
    final seconds = elapsed.inSeconds < 0 ? 0 : elapsed.inSeconds;
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final summary = record?.summary;
    final (statusLabel, queueText) = switch (status) {
      ConsultStatus.pending => ('약사를 찾고 있어요', '약사 연결을 기다리는 중이에요'),
      ConsultStatus.approved => (
        '약사가 처방을 완료했어요',
        '처방약: ${record?.approvedDrugName ?? '-'}',
      ),
      ConsultStatus.rejected => (
        '상담이 거절되었어요',
        record?.decisionReason ?? '사유가 별도로 전달되지 않았습니다.',
      ),
    };
    final step3Description = switch (status) {
      ConsultStatus.approved => '화상 상담이 끝났다면 자판기에서 QR을 스캔해 수령하세요',
      _ when pharmacistIn => '약사가 화상 상담방에서 기다리고 있어요',
      _ => '연결되면 카메라·마이크를 확인해요',
    };

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: consultHeaderCream,
      ),
      child: ColoredBox(
        color: consultCream,
        child: Column(
          children: [
            ConsultCreamHeader(
              title: '약사상담',
              subtitle: '전문 약사와 안전하게 상담해요',
              onScanQr: onScanQr,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _WaitingCard(
                      statusLabel: statusLabel,
                      dialLabel: status == ConsultStatus.pending
                          ? '대기 시간'
                          : '상담',
                      dialValue: switch (status) {
                        ConsultStatus.pending => _elapsedLabel,
                        ConsultStatus.approved => '완료',
                        ConsultStatus.rejected => '종료',
                      },
                      queueText: queueText,
                      requestedAt: requestedAt,
                      progress: status == ConsultStatus.pending ? 0.6 : 1,
                    ),
                    const SizedBox(height: 14),
                    _ProgressCard(
                      matchingDone: status != ConsultStatus.pending,
                      entryDone: status == ConsultStatus.approved,
                      entryDescription: step3Description,
                    ),
                    if (status == ConsultStatus.pending && roomReady) ...[
                      const SizedBox(height: 14),
                      _JoinNowButton(pharmacistIn: pharmacistIn, onTap: onJoin),
                    ],
                    if (summary != null) ...[
                      const SizedBox(height: 14),
                      _SummaryCard(child: ConsultSummaryBody(summary: summary)),
                    ] else if (status == ConsultStatus.approved) ...[
                      const SizedBox(height: 14),
                      const _SummaryCard(
                        child: Text(
                          '약사가 상담 내용을 정리하고 있어요. 검토가 끝나면 여기에 자동으로 표시돼요.',
                          style: TextStyle(
                            color: Color(0xFF2B2B2B),
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    const _PrivacyNotice(),
                    if (status == ConsultStatus.pending) ...[
                      const SizedBox(height: 14),
                      _BottomActionButton(
                        label: '상담 요청 취소',
                        icon: Icons.close,
                        onTap: onCancel,
                      ),
                    ] else if (status == ConsultStatus.rejected) ...[
                      const SizedBox(height: 14),
                      _BottomActionButton(
                        label: '챗봇으로 돌아가기',
                        onTap: onOpenChatbot,
                      ),
                    ],
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

class _WaitingCard extends StatelessWidget {
  const _WaitingCard({
    required this.statusLabel,
    required this.dialLabel,
    required this.dialValue,
    required this.queueText,
    required this.requestedAt,
    required this.progress,
  });

  final String statusLabel;
  final String dialLabel;
  final String dialValue;
  final String queueText;
  final DateTime requestedAt;
  final double progress;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
    decoration: BoxDecoration(
      color: _cardCream,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: consultBeige),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F3E2723),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: _StatusChip(icon: Icons.sensors, label: statusLabel),
        ),
        const SizedBox(height: 14),
        Center(
          child: Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              color: consultMint,
              shape: BoxShape.circle,
              border: Border.all(color: consultGreen, width: 7),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dialLabel,
                  style: const TextStyle(
                    color: consultDeepGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  dialValue,
                  style: const TextStyle(
                    color: consultDeepGreen,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                queueText,
                style: const TextStyle(
                  color: consultBrown,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${formatTime(requestedAt)} 신청',
              style: const TextStyle(color: consultMutedBrown, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            color: consultGreen,
            backgroundColor: consultBeige,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '앱을 잠시 벗어나도 이 화면으로 돌아오면 진행 상황이 이어서 보여요.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: consultMutedBrown,
            fontSize: 13,
            height: 1.45,
          ),
        ),
      ],
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: consultMint,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Icon(icon, color: consultDeepGreen, size: 14)
        else
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: consultDeepGreen,
              shape: BoxShape.circle,
            ),
          ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: consultDeepGreen,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

enum _StepState { done, active, pending }

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.matchingDone,
    required this.entryDone,
    required this.entryDescription,
  });

  final bool matchingDone;
  final bool entryDone;
  final String entryDescription;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    decoration: BoxDecoration(
      color: _cardCream,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '연결 진행 상황',
          style: TextStyle(
            color: consultBrown,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const _ProgressStep(
          icon: Icons.check,
          title: '상담 요청 완료',
          description: '증상과 복용 정보를 전달했어요',
          state: _StepState.done,
        ),
        const Divider(height: 1, indent: 46, color: consultLine),
        _ProgressStep(
          icon: matchingDone ? Icons.check : Icons.headset_mic_outlined,
          title: '상담 가능한 약사 확인',
          description: '가장 빠른 약사를 연결하고 있어요',
          state: matchingDone ? _StepState.done : _StepState.active,
        ),
        const Divider(height: 1, indent: 46, color: consultLine),
        _ProgressStep(
          icon: entryDone ? Icons.check : Icons.videocam_outlined,
          title: '화상 상담 입장',
          description: entryDescription,
          state: entryDone ? _StepState.done : _StepState.pending,
        ),
      ],
    ),
  );
}

class _ProgressStep extends StatelessWidget {
  const _ProgressStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.state,
  });

  final IconData icon;
  final String title;
  final String description;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final pending = state == _StepState.pending;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: pending ? consultLine : consultMint,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: pending ? consultMutedBrown : consultDeepGreen,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: pending ? consultMutedBrown : consultBrown,
                    fontSize: 13,
                    fontWeight: state == _StepState.active
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    color: consultMutedBrown,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (state == _StepState.active) const _StatusChip(label: '진행 중'),
        ],
      ),
    );
  }
}

/// 화상방이 준비되면 나오는 입장 버튼. 약사가 들어오면 강조색으로 바뀌며 깜빡인다.
class _JoinNowButton extends StatefulWidget {
  const _JoinNowButton({required this.pharmacistIn, required this.onTap});

  final bool pharmacistIn;
  final VoidCallback onTap;

  @override
  State<_JoinNowButton> createState() => _JoinNowButtonState();
}

class _JoinNowButtonState extends State<_JoinNowButton>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.pharmacistIn) _pulse.repeat();
  }

  @override
  void didUpdateWidget(covariant _JoinNowButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pharmacistIn && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!widget.pharmacistIn) {
      _pulse.reset();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pharmacistIn = widget.pharmacistIn;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        // 0 → 1 → 0 으로 퍼졌다 사라지는 노란 그림자
        final t = pharmacistIn ? (1 - (_pulse.value * 2 - 1).abs()) : 0.0;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              if (pharmacistIn)
                BoxShadow(
                  color: const Color(0xFFFFD54F)
                      .withValues(alpha: 0.6 * (1 - t)),
                  spreadRadius: 8 * t,
                ),
            ],
          ),
          child: child,
        );
      },
      child: SizedBox(
        height: 50,
        child: FilledButton(
          onPressed: widget.onTap,
          style: FilledButton.styleFrom(
            backgroundColor: pharmacistIn
                ? const Color(0xFF3E2723)
                : consultGreen,
            foregroundColor: pharmacistIn
                ? const Color(0xFFFFD54F)
                : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: Text(
            pharmacistIn ? '🔔 약사가 들어왔어요 — 지금 입장하기' : '🎥 화상 상담 입장하기',
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFDF5),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFF1E3B8)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📝 상담 요약',
          style: TextStyle(
            color: Color(0xFF593D0D),
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    ),
  );
}

class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: consultMint,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.verified_user_outlined, color: consultDeepGreen, size: 20),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '상담 내용은 안전하게 보호돼요',
                style: TextStyle(
                  color: consultDeepGreen,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2),
              Text(
                '상담 기록은 서비스 제공 목적 외에는 사용하지 않습니다.',
                style: TextStyle(color: consultDeepGreen, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _BottomActionButton extends StatelessWidget {
  const _BottomActionButton({
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: _dangerBackground,
        foregroundColor: _danger,
        side: const BorderSide(color: Color(0xFFF2CFC9)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 6)],
          Text(label),
        ],
      ),
    ),
  );
}

class _VideoConsultationEntryView extends StatefulWidget {
  const _VideoConsultationEntryView({
    required this.onBack,
    required this.onScanQr,
  });

  final VoidCallback onBack;
  final VoidCallback onScanQr;

  @override
  State<_VideoConsultationEntryView> createState() =>
      _VideoConsultationEntryViewState();
}

class _VideoConsultationEntryViewState
    extends State<_VideoConsultationEntryView> {
  // 실제 카메라 권한 확인 대신 잠시 확인 중 상태를 보여준다.
  static const _deviceCheckDelay = Duration(milliseconds: 1200);

  Timer? _deviceCheckTimer;
  bool _checkingDevices = true;
  bool _cameraEnabled = true;
  bool _microphoneEnabled = true;

  @override
  void initState() {
    super.initState();
    _deviceCheckTimer = Timer(_deviceCheckDelay, () {
      if (mounted) setState(() => _checkingDevices = false);
    });
  }

  @override
  void dispose() {
    _deviceCheckTimer?.cancel();
    super.dispose();
  }

  void _toggleCamera() {
    if (!_checkingDevices) setState(() => _cameraEnabled = !_cameraEnabled);
  }

  void _toggleMicrophone() {
    if (!_checkingDevices) {
      setState(() => _microphoneEnabled = !_microphoneEnabled);
    }
  }

  void _enterConsultation() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const VideoConsultationPage()),
    );
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light.copyWith(statusBarColor: _darkHeader),
    child: ColoredBox(
      color: _darkBody,
      child: Column(
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(
              color: _darkHeader,
              border: Border(bottom: BorderSide(color: Color(0x1AFFFFFF))),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  const AppStatusBar(color: Colors.white),
                  SizedBox(
                    height: 60,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 16, 0),
                      child: Row(
                        children: [
                          Material(
                            color: const Color(0x14FFFFFF),
                            shape: const CircleBorder(),
                            child: InkWell(
                              onTap: widget.onBack,
                              customBorder: const CircleBorder(),
                              child: const SizedBox(
                                width: 36,
                                height: 36,
                                child: Icon(
                                  Icons.chevron_left,
                                  color: Colors.white,
                                  semanticLabel: '이전 화면',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '화상 상담 입장',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '입장 전 화면과 소리를 확인해 주세요',
                                  style: TextStyle(
                                    color: Color(0xB8FFFFFF),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          QrScanPill(onTap: widget.onScanQr, dark: true),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CameraPreview(
                    cameraEnabled: _cameraEnabled,
                    microphoneEnabled: _microphoneEnabled,
                    onToggleCamera: _toggleCamera,
                    onToggleMicrophone: _toggleMicrophone,
                  ),
                  const SizedBox(height: 12),
                  _ReadyMessage(checking: _checkingDevices),
                  const SizedBox(height: 12),
                  _DeviceCheckTile(
                    icon: Icons.videocam_outlined,
                    title: '카메라',
                    state: _checkingDevices
                        ? '확인 중...'
                        : _cameraEnabled
                        ? '정상 작동 중'
                        : '꺼짐',
                    enabled: _cameraEnabled,
                    onTap: _toggleCamera,
                  ),
                  const SizedBox(height: 12),
                  _DeviceCheckTile(
                    icon: Icons.mic_none,
                    title: '마이크',
                    state: _checkingDevices
                        ? '확인 중...'
                        : _microphoneEnabled
                        ? '입력 감지됨'
                        : '꺼짐',
                    enabled: _microphoneEnabled,
                    onTap: _toggleMicrophone,
                  ),
                  const SizedBox(height: 12),
                  _DeviceCheckTile(
                    icon: Icons.volume_up_outlined,
                    title: '스피커',
                    state: '눌러서 소리를 테스트해보세요',
                    enabled: true,
                    onTap: () => SystemSound.play(SystemSoundType.click),
                  ),
                  const SizedBox(height: 12),
                  _PharmacistRow(ready: !_checkingDevices),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: _enterConsultation,
                      style: FilledButton.styleFrom(
                        backgroundColor: consultGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      icon: const Icon(Icons.videocam_outlined),
                      label: const Text('화상 상담 입장하기'),
                    ),
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

class _CameraPreview extends StatelessWidget {
  const _CameraPreview({
    required this.cameraEnabled,
    required this.microphoneEnabled,
    required this.onToggleCamera,
    required this.onToggleMicrophone,
  });

  final bool cameraEnabled;
  final bool microphoneEnabled;
  final VoidCallback onToggleCamera;
  final VoidCallback onToggleMicrophone;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(
          color: Color(0x24263C34),
          blurRadius: 24,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 300,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (cameraEnabled)
              Image.asset(
                'assets/figma/pharmacist_preview.png',
                fit: BoxFit.cover,
                alignment: const Alignment(0, -0.6),
                semanticLabel: '상담 화면 미리보기',
              )
            else
              const ColoredBox(
                color: Color(0xFF2A3330),
                child: Center(
                  child: Icon(
                    Icons.videocam_off_outlined,
                    color: Color(0x80FFFFFF),
                    size: 40,
                  ),
                ),
              ),
            Positioned(
              left: 14,
              top: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xB81B1614),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: _lightMint, size: 7),
                    SizedBox(width: 6),
                    Text(
                      '상담 화면 미리보기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 14,
              top: 14,
              child: _PreviewControl(
                icon: Icons.cameraswitch_outlined,
                label: '카메라 전환',
                size: 36,
                bordered: false,
                onTap: () {},
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _PreviewControl(
                    icon: cameraEnabled
                        ? Icons.videocam_outlined
                        : Icons.videocam_off_outlined,
                    label: cameraEnabled ? '카메라 끄기' : '카메라 켜기',
                    onTap: onToggleCamera,
                  ),
                  const SizedBox(width: 12),
                  _PreviewControl(
                    icon: microphoneEnabled
                        ? Icons.mic_none
                        : Icons.mic_off_outlined,
                    label: microphoneEnabled ? '마이크 끄기' : '마이크 켜기',
                    onTap: onToggleMicrophone,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PreviewControl extends StatelessWidget {
  const _PreviewControl({
    required this.icon,
    required this.label,
    required this.onTap,
    this.size = 44,
    this.bordered = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double size;
  final bool bordered;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: Material(
      color: const Color(0xB81B1614),
      shape: CircleBorder(
        side: bordered
            ? const BorderSide(color: Color(0x29FFFFFF))
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    ),
  );
}

class _ReadyMessage extends StatelessWidget {
  const _ReadyMessage({required this.checking});

  final bool checking;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0x1ADDEEE8),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0x4D65D6A8)),
    ),
    child: Row(
      children: [
        Icon(
          checking ? Icons.hourglass_top : Icons.check_circle_outline,
          color: _lightMint,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            checking ? '카메라 권한을 확인하는 중이에요...' : '카메라와 마이크가 정상적으로 연결됐어요.',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _DeviceCheckTile extends StatelessWidget {
  const _DeviceCheckTile({
    required this.icon,
    required this.title,
    required this.state,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String state;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0x0FFFFFFF),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: Color(0x1FFFFFFF)),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 54,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
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
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      state,
                      style: const TextStyle(
                        color: Color(0x9EFFFFFF),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              _MiniToggle(on: enabled),
            ],
          ),
        ),
      ),
    ),
  );
}

/// HTML의 `.device-status2` 작은 토글 (34×20).
class _MiniToggle extends StatelessWidget {
  const _MiniToggle({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 150),
    width: 34,
    height: 20,
    padding: const EdgeInsets.all(2),
    alignment: on ? Alignment.centerRight : Alignment.centerLeft,
    decoration: BoxDecoration(
      color: on ? consultGreen : _toggleOff,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Container(
      width: 16,
      height: 16,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    ),
  );
}

class _PharmacistRow extends StatelessWidget {
  const _PharmacistRow({required this.ready});

  final bool ready;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: consultMint,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.person_outline, color: consultGreen, size: 22),
      ),
      const SizedBox(width: 10),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '약사 상담실',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '약사가 입장하면 자동으로 연결돼요',
              style: TextStyle(color: Color(0x9EFFFFFF), fontSize: 11),
            ),
          ],
        ),
      ),
      _StatusChip(label: ready ? '연결 준비됨' : '준비 중'),
    ],
  );
}
