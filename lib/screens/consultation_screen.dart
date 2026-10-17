import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/models.dart';
import '../utils/format.dart';
import '../widgets/consult_header.dart';
import 'consultation_entry_page.dart';
import '../config/app_config.dart';
import '../data/api_client.dart';
import '../data/app_session.dart';
import '../data/consultation_api.dart';
import '../calls/call_room.dart';
import '../calls/consultation_chat.dart';

const _cardCream = Color(0xFFFFFCF6);
const _danger = Color(0xFFC94C43);
const _dangerBackground = Color(0xFFFBE7E4);

/// 약사 상담 흐름: 연결 대기 → 화상 상담 입장.
///
/// - 하단 "상담하기"로 들어오면([direct]) 화상방이 준비되는 즉시 입장 화면으로 넘어간다.
/// - 챗봇의 "약사에게 바로 상담하기"로 들어오면 대기 화면에 머물며 입장 버튼을 보여준다.
/// - [record]를 주면 지난 상담의 결과(처방 완료·거절)를 보여준다.
/// - 미리보기가 아니면 백엔드 상담 API로 요청·상태 확인·취소를 한다.
class ConsultationScreen extends StatefulWidget {
  const ConsultationScreen({
    required this.onScanQr,
    required this.onOpenChatbot,
    this.direct = true,
    this.record,
    this.room,
    this.chat,
    this.onClosed,
    this.api,
    super.key,
  });

  final VoidCallback onScanQr;

  /// 상담이 취소돼 다음에 들어오면 새 상담을 요청해야 할 때.
  final VoidCallback? onClosed;

  /// 테스트에서 가짜 서버를 넣을 때 쓴다.
  final ConsultationApi? api;

  /// 상담 요청 취소, "챗봇으로 돌아가기" 후 이동할 곳.
  final VoidCallback onOpenChatbot;
  final bool direct;
  final ConsultRecord? record;
  final CallRoom? room;
  final ConsultationChat? chat;

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  // 미리보기 모드는 화상방 준비·약사 입장을 시간차로 흉내 낸다.
  static const _roomReadyDelay = Duration(seconds: 3);
  static const _pharmacistJoinDelay = Duration(seconds: 8);

  // 실제 모드: 백엔드 HTML과 같이 3초마다 상담 상태와 약사 입장 여부를 확인한다.
  static const _pollInterval = Duration(seconds: 3);

  /// 지난 상담 보기(record)가 아니고 미리보기도 아니면 실제 서버로 진행한다.
  bool get _live => !AppConfig.preview.value && widget.record == null;
  late final ConsultationApi _api = widget.api ?? ConsultationApi();
  ConsultationSnapshot? _snapshot;
  bool _requesting = false;
  String? _requestError;
  bool _polling = false;

  late DateTime _requestedAt = widget.record?.createdAt ?? DateTime.now();
  ConsultRecord? _previewRecord;
  ConsultRecord? get _record =>
      _snapshot?.record ?? _previewRecord ?? widget.record;
  ConsultStatus get _status => _record?.status ?? ConsultStatus.pending;
  late bool _roomReady = widget.record != null;
  Duration _elapsed = Duration.zero;
  bool _pharmacistIn = false;
  bool _showingEntry = false;
  bool _leftCall = false;
  final _timers = <Timer>[];

  @override
  void initState() {
    super.initState();
    if (_live) {
      _requestConsultation();
      return;
    }
    if (widget.room != null) {
      _roomReady = true;
      _showingEntry = widget.direct;
      return;
    }
    if (!AppConfig.preview.value) return;
    if (_status != ConsultStatus.pending || _record?.endedAt != null) return;
    _startClock();
    if (_roomReady) {
      _schedulePharmacistJoin();
    } else {
      _timers.add(
        Timer(_roomReadyDelay, () {
          if (!mounted ||
              _status != ConsultStatus.pending ||
              _record?.endedAt != null) {
            return;
          }
          setState(() {
            _roomReady = true;
            _showingEntry = widget.direct;
          });
          _schedulePharmacistJoin();
        }),
      );
    }
  }

  void _startClock() {
    _tickClock();
    _timers.add(
      Timer.periodic(const Duration(seconds: 1), (_) => _tickClock()),
    );
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

  void _stopTimers() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
  }

  /// 진행 중인 상담이 있으면 이어서 보고, 없으면 새로 요청한다.
  Future<void> _requestConsultation() async {
    final userId = AppSession.instance.userId;
    if (userId == null) {
      setState(() => _requestError = '사용자 정보를 확인하지 못했어요. 다시 로그인해주세요.');
      return;
    }
    setState(() {
      _requesting = true;
      _requestError = null;
    });
    try {
      final snapshot = await _api.findOrCreate(
        userId: userId,
        chatSummary: widget.direct ? '' : AppSession.instance.chatSummary,
      );
      if (!mounted) return;
      _applySnapshot(snapshot, first: true);
      if (!snapshot.cancelled &&
          (!snapshot.finished || snapshot.record.summary == null)) {
        _startClock();
        _timers.add(Timer.periodic(_pollInterval, (_) => _poll()));
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _requestError = error is ApiException
              ? error.message
              : '서버에 연결하지 못했어요. 네트워크 상태를 확인해주세요.',
        );
      }
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  void _applySnapshot(ConsultationSnapshot snapshot, {bool first = false}) {
    final session = AppSession.instance;
    if (snapshot.cancelled) {
      // 약사 웹이나 다른 화면에서 취소된 경우
      _closeLive();
      return;
    }
    setState(() {
      _snapshot = snapshot;
      _requestedAt = snapshot.record.createdAt;
    });
    session.setLiveConsultation(snapshot.record);
    final roomUrl = snapshot.roomUrl;
    if (snapshot.finished) {
      if (session.callConsultationId == snapshot.id) session.clearCallRoom();
      return;
    }
    if (roomUrl != null && session.callConsultationId != snapshot.id) {
      try {
        session.attachCallRoom(
          CallRoom.fromJson(snapshot.raw),
          consultationId: snapshot.id,
        );
      } on FormatException {
        return;
      }
    }
    if (roomUrl != null && !_roomReady) {
      setState(() {
        _roomReady = true;
        // 하단 "상담하기"로 들어왔으면 대기 화면을 건너뛰고 바로 입장 화면으로 간다.
        if (first && widget.direct && _status == ConsultStatus.pending) {
          _showingEntry = true;
        }
      });
    }
  }

  Future<void> _poll() async {
    final current = _snapshot;
    if (current == null || _polling) return;
    _polling = true;
    try {
      final next = await _api.get(current.id);
      if (!mounted) return;
      _applySnapshot(next);
      if (next.cancelled || (next.finished && next.record.summary != null)) {
        _stopTimers();
        return;
      }
      if (!next.finished &&
          next.roomUrl != null &&
          next.record.summary == null) {
        final inRoom = await _api.pharmacistInRoom(next.id);
        if (mounted && inRoom != null && inRoom != _pharmacistIn) {
          setState(() => _pharmacistIn = inRoom);
        }
      }
    } catch (_) {
      // 네트워크가 잠깐 끊긴 경우 다음 확인 때 다시 시도한다.
    } finally {
      _polling = false;
    }
  }

  void _closeLive() {
    _stopTimers();
    AppSession.instance.clearCallRoom();
    AppSession.instance.cancelConsultation();
    widget.onClosed?.call();
    widget.onOpenChatbot();
  }

  @override
  void dispose() {
    _stopTimers();
    if (widget.api == null) _api.close();
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
    if (_live) {
      final snapshot = _snapshot;
      if (snapshot != null) {
        try {
          await _api.cancel(snapshot.id);
        } catch (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  error is ApiException
                      ? '취소하지 못했어요: ${error.message}'
                      : '상담 취소를 반영하지 못했어요. 다시 시도해주세요.',
                ),
              ),
            );
          }
          return;
        }
      }
      if (mounted) _closeLive();
      return;
    }
    if (widget.room != null) {
      if (widget.chat == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('상담 취소에 필요한 서버 연결 정보가 없어요.')),
        );
        return;
      }
      try {
        await widget.chat!.cancel();
        if (!mounted) return;
        AppSession.instance.clearCallRoom();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('상담 취소를 반영하지 못했어요. 다시 시도해주세요.')),
          );
        }
        return;
      }
    }
    _stopTimers();
    AppSession.instance.cancelConsultation();
    widget.onClosed?.call();
    widget.onOpenChatbot();
  }

  /// 환자가 통화를 나가면 서버 종료 없이 결과 대기 화면으로 돌아온다.
  void _handleCallEnded() {
    _leftCall = true;
    if (_live) {
      setState(() => _showingEntry = false);
      _poll();
      return;
    }
    _stopTimers();
    if (widget.room == null) {
      AppSession.instance.endPreviewConsultation();
    }
    setState(() {
      _showingEntry = false;
      _previewRecord = widget.room == null
          ? AppSession.instance.consultation
          : ConsultRecord(
              id: AppSession.instance.callConsultationId ?? 'completed',
              createdAt: _requestedAt,
              status: _status,
              summary: widget.chat?.summary,
            );
    });
    if (widget.room != null) AppSession.instance.clearCallRoom();
  }

  @override
  Widget build(BuildContext context) {
    // 실제 모드에서 상담이 만들어지기 전: 요청 중이거나 실패한 상태를 보여준다.
    final waitingForServer = _live && _snapshot == null;
    return Column(
      children: [
        if (AppConfig.preview.value &&
            widget.record == null &&
            widget.room == null)
          Material(
            color: const Color(0xFFFFE7AC),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('예시 상담 상태', style: TextStyle(fontSize: 12)),
                  ),
                  DropdownButton<ConsultStatus>(
                    value: _status,
                    items: const [
                      DropdownMenuItem(
                        value: ConsultStatus.pending,
                        child: Text('대기'),
                      ),
                      DropdownMenuItem(
                        value: ConsultStatus.approved,
                        child: Text('승인'),
                      ),
                      DropdownMenuItem(
                        value: ConsultStatus.rejected,
                        child: Text('거절'),
                      ),
                    ],
                    onChanged: (status) {
                      if (status == null) return;
                      _stopTimers();
                      final session = AppSession.instance;
                      if (session.consultation == null) {
                        session.startConsultation(direct: widget.direct);
                      }
                      session.previewDecision(status);
                      setState(() {
                        _previewRecord = session.consultation;
                        _showingEntry = false;
                        _roomReady = status == ConsultStatus.pending;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: _showingEntry
              ? ConsultationEntryPage(
                  room: widget.room,
                  chat: widget.chat,
                  onBack: () => setState(() => _showingEntry = false),
                  onScanQr: widget.onScanQr,
                  onEnd: _handleCallEnded,
                )
              : _PharmacistWaitingView(
                  status: _status,
                  record: _record,
                  requestedAt: _requestedAt,
                  elapsed: _elapsed,
                  roomReady: _roomReady,
                  pharmacistIn: _pharmacistIn,
                  notice: !waitingForServer
                      ? (_leftCall && _record?.summary == null
                            ? (
                                '상담 결과를 기다리고 있어요',
                                '약사가 상담을 마무리하고 검토한 요약을 공개하면 여기에 표시돼요.',
                              )
                            : null)
                      : _requestError != null
                      ? ('상담 요청에 실패했어요', _requestError!)
                      : ('상담을 요청하고 있어요', '서버가 잠들어 있으면 최대 1분쯤 걸릴 수 있어요.'),
                  onRetry: waitingForServer && _requestError != null
                      ? _requestConsultation
                      : null,
                  requesting: _requesting,
                  onScanQr: widget.onScanQr,
                  onJoin: () => setState(() => _showingEntry = true),
                  onCancel: _confirmCancel,
                  onOpenChatbot: widget.onOpenChatbot,
                ),
        ),
        if (AppConfig.preview.value &&
            !widget.direct &&
            widget.record == null &&
            AppSession.instance.consultationChatSummary.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '약사에게 전달할 대화\n${AppSession.instance.consultationChatSummary}',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
      ],
    );
  }
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
    this.notice,
    this.onRetry,
    this.requesting = false,
  });

  /// 상담이 만들어지기 전 안내(제목, 내용). 있으면 상태 문구 대신 보여준다.
  final (String, String)? notice;
  final VoidCallback? onRetry;
  final bool requesting;
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
    final ended = record?.endedAt != null;
    final (statusLabel, queueText) = notice != null
        ? notice!
        : ended && status == ConsultStatus.pending
        ? ('상담이 종료되었어요', '상담 내역에서 결과를 확인해주세요.')
        : switch (status) {
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
                      dialLabel: status == ConsultStatus.pending && !ended
                          ? '대기 시간'
                          : '상담',
                      dialValue: ended
                          ? '종료'
                          : switch (status) {
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
                    if (notice == null &&
                        status == ConsultStatus.pending &&
                        roomReady &&
                        !ended) ...[
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
                    if (onRetry != null) ...[
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: requesting ? null : onRetry,
                          style: FilledButton.styleFrom(
                            backgroundColor: consultGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          icon: const Icon(Icons.refresh),
                          label: const Text('다시 요청하기'),
                        ),
                      ),
                    ],
                    if (status == ConsultStatus.pending && !ended) ...[
                      const SizedBox(height: 14),
                      _BottomActionButton(
                        label: '상담 요청 취소',
                        icon: Icons.close,
                        onTap: onCancel,
                      ),
                    ] else if (status == ConsultStatus.rejected || ended) ...[
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
