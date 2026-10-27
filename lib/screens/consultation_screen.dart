import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/models.dart';
import '../utils/format.dart';
import '../widgets/consult_header.dart';
import '../widgets/pharmacist_theme.dart';
import 'consultation_entry_page.dart';
import '../config/app_config.dart';
import '../data/api_client.dart';
import '../data/app_session.dart';
import '../data/consultation_api.dart';
import '../calls/call_room.dart';
import '../calls/consultation_chat.dart';

// 약사 연결 대기 화면 색. 공통 값은 widgets/pharmacist_theme.dart.
const _brown = pharmBrown;
const _muted = pharmMuted;
const _yellow = pharmYellow;
const _pageBg = pharmPageBg;
const _headerBg = pharmHeaderBg;
const _green = pharmGreen;
const _mint = pharmMint;
const _whiteCard = pharmWhiteCard;
const _divider = Color(0xFFD3CABA);
const _pendingCircle = Color(0xFFF3EEE5);
const _privacyBorder = Color(0xFFDBE5DC);
const _danger = Color(0xFFC94C43);
const _dangerBackground = Color(0xFFFBE7E4);

/// 요청 전 확인 → 명시적 요청 → 약사 실제 입장 대기 → 영상 상담.
class ConsultationScreen extends StatefulWidget {
  const ConsultationScreen({
    required this.onScanQr,
    required this.onOpenChatbot,
    this.direct = true,
    this.isActive = true,
    this.onOpenConsultation,
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
  final bool isActive;
  final VoidCallback? onOpenConsultation;
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
  bool _requested = false;
  bool _cancelling = false;
  int _requestGeneration = 0;
  bool _entryNotified = false;
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
    _requested = widget.record != null;
  }

  @override
  void didUpdateWidget(covariant ConsultationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _notifyEntry());
    }
  }

  void _notifyEntry() {
    if (!mounted ||
        (!widget.isActive && widget.onOpenConsultation == null) ||
        !_pharmacistIn ||
        _entryNotified ||
        _showingEntry) {
      return;
    }
    _entryNotified = true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('약사가 상담방에 입장했어요. 입장 버튼을 눌러주세요.'),
        duration: const Duration(seconds: 5),
        // 액션이 있는 SnackBar는 기본적으로 자동으로 닫히지 않으므로 명시한다.
        persist: false,
        action: widget.onOpenConsultation == null
            ? null
            : SnackBarAction(
                label: '상담 화면',
                onPressed: widget.onOpenConsultation!,
              ),
      ),
    );
  }

  void _beginRequest() {
    if (_requesting || _requested) return;
    setState(() {
      _requested = true;
      _requestGeneration++;
      _requestedAt = DateTime.now();
    });
    if (_live) {
      _requestConsultation();
      return;
    }
    if (!AppConfig.preview.value) return;
    AppSession.instance.startConsultation(direct: widget.direct);
    _startClock();
    _timers.add(
      Timer(_roomReadyDelay, () {
        if (!mounted) return;
        setState(() => _roomReady = true);
        _schedulePharmacistJoin();
      }),
    );
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
      if (mounted) {
        setState(() => _pharmacistIn = true);
        _notifyEntry();
      }
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
    final generation = _requestGeneration;
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
      if (!mounted || generation != _requestGeneration) return;
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
      });
    }
  }

  Future<void> _poll() async {
    final current = _snapshot;
    final generation = _requestGeneration;
    if (current == null || _polling || _cancelling) return;
    _polling = true;
    try {
      final next = await _api.get(current.id);
      if (!mounted || _cancelling || generation != _requestGeneration) return;
      _applySnapshot(next);
      if (next.cancelled || (next.finished && next.record.summary != null)) {
        _stopTimers();
        return;
      }
      if (!next.finished &&
          next.roomUrl != null &&
          next.record.summary == null) {
        final inRoom = await _api.pharmacistInRoom(next.id);
        if (mounted && !_cancelling && generation == _requestGeneration) {
          setState(() => _pharmacistIn = inRoom == true);
          _notifyEntry();
        }
      }
    } catch (_) {
      if (mounted) setState(() => _pharmacistIn = false);
      // 네트워크가 잠깐 끊긴 경우 다음 확인 때 다시 시도한다.
    } finally {
      _polling = false;
    }
  }

  void _closeLive() {
    _stopTimers();
    AppSession.instance.clearCallRoom();
    AppSession.instance.cancelConsultation();
    setState(() {
      _requestGeneration++;
      _requested = false;
      _snapshot = null;
      _previewRecord = null;
      _roomReady = false;
      _pharmacistIn = false;
      _entryNotified = false;
      _showingEntry = false;
      _leftCall = false;
      _requestError = null;
      _elapsed = Duration.zero;
    });
  }

  @override
  void dispose() {
    _stopTimers();
    if (widget.api == null) _api.close();
    super.dispose();
  }

  Future<void> _confirmCancel() async {
    if (_cancelling || _requesting) return;
    setState(() => _cancelling = true);
    try {
      await _cancelConfirmed();
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  Future<void> _cancelConfirmed() async {
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
    _closeLive();
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
    final waitingForServer = _requested && _live && _snapshot == null;
    return Column(
      children: [
        if (_requested &&
            AppConfig.preview.value &&
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
                  room: widget.room ?? AppSession.instance.callRoom,
                  chat: widget.chat ?? AppSession.instance.callChat,
                  onBack: () => setState(() => _showingEntry = false),
                  onScanQr: widget.onScanQr,
                  onEnd: _handleCallEnded,
                )
              : _PharmacistWaitingView(
                  requested: _requested,
                  onRequest: _beginRequest,
                  status: _status,
                  record: _record,
                  requestedAt: _requestedAt,
                  elapsed: _elapsed,
                  roomReady: _roomReady,
                  pharmacistIn: _pharmacistIn,
                  notice: !_requested
                      ? ('약사 상담을 요청해보세요', '가운데 버튼을 누르면 상담 요청이 전달돼요.')
                      : !waitingForServer
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
                  requesting: _requesting || _cancelling,
                  onScanQr: widget.onScanQr,
                  onJoin: () {
                    if (_pharmacistIn) setState(() => _showingEntry = true);
                  },
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
    required this.requested,
    required this.onRequest,
    this.notice,
    this.onRetry,
    this.requesting = false,
  });

  /// 상담이 만들어지기 전 안내(제목, 내용). 있으면 상태 문구 대신 보여준다.
  final bool requested;
  final VoidCallback onRequest;
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
    final preview = AppConfig.preview.value;
    final summary = record?.summary;
    final ended = record?.endedAt != null;
    final waiting = requested && status == ConsultStatus.pending && !ended;
    final (statusLabel, queueText) = notice != null
        ? notice!
        : ended && status == ConsultStatus.pending
        ? ('상담이 종료되었어요', '상담 내역에서 결과를 확인해주세요.')
        : switch (status) {
            ConsultStatus.pending =>
              pharmacistIn
                  ? ('약사가 입장했어요', '아래 입장 버튼으로 상담을 시작하세요')
                  : ('약사 입장을 기다리고 있어요', '약사 연결을 기다리는 중이에요'),
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
    // 미리보기 모드는 예시 데이터라는 것을 화면에 함께 밝힌다.
    final example = preview && notice == null && waiting ? ' · 예시' : '';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: _headerBg),
      child: ColoredBox(
        color: _pageBg,
        child: Column(
          children: [
            PharmacistHeader(
              title: '약사상담',
              subtitle: '전문 약사와 안전하게 상담해요',
              onScanQr: onScanQr,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (preview) ...[
                      const Center(child: DemoModeChip()),
                      const SizedBox(height: 14),
                    ],
                    _WaitingCard(
                      statusLabel: '$statusLabel$example',
                      onDialTap: requesting
                          ? null
                          : !requested
                          ? onRequest
                          : onRetry ?? (waiting ? onCancel : null),
                      actionLabel: requesting
                          ? '처리 중...'
                          : !requested
                          ? '상담 요청하기'
                          : onRetry != null
                          ? '다시 요청하기'
                          : waiting
                          ? '상담 요청 취소'
                          : null,
                      dialLabel: !requested
                          ? '약사 상담'
                          : waiting
                          ? '대기 시간${example.isEmpty ? '' : ' 예시'}'
                          : '상담',
                      dialValue: !requested
                          ? '시작'
                          : ended
                          ? '종료'
                          : switch (status) {
                              ConsultStatus.pending => _elapsedLabel,
                              ConsultStatus.approved => '완료',
                              ConsultStatus.rejected => '종료',
                            },
                      queueText: queueText,
                      requestedAt: requested ? requestedAt : null,
                      progress: !requested
                          ? 0
                          : status == ConsultStatus.pending
                          ? 0.66
                          : 1,
                    ),
                    const SizedBox(height: 16),
                    if (requested)
                      _ProgressCard(
                        matchingDone:
                            pharmacistIn || status != ConsultStatus.pending,
                        entryDone: status == ConsultStatus.approved,
                        entryDescription: step3Description,
                      ),
                    if (notice == null &&
                        waiting &&
                        roomReady &&
                        pharmacistIn) ...[
                      const SizedBox(height: 20),
                      _JoinNowButton(pharmacistIn: pharmacistIn, onTap: onJoin),
                    ],
                    if (summary != null) ...[
                      const SizedBox(height: 16),
                      _SummaryCard(child: ConsultSummaryBody(summary: summary)),
                    ] else if (status == ConsultStatus.approved) ...[
                      const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
                    _PrivacyNotice(preview: preview),
                    if (status == ConsultStatus.rejected || ended) ...[
                      const SizedBox(height: 16),
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
    this.onDialTap,
    this.actionLabel,
  });

  final String statusLabel;
  final String dialLabel;
  final String dialValue;
  final String queueText;
  final DateTime? requestedAt;
  final VoidCallback? onDialTap;
  final String? actionLabel;
  final double progress;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
    decoration: _whiteCard,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: _StatusChip(icon: Icons.sensors, label: statusLabel),
        ),
        const SizedBox(height: 18),
        Center(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onDialTap,
              customBorder: const CircleBorder(),
              child: Container(
                width: 164,
                height: 164,
                decoration: BoxDecoration(
                  color: _mint,
                  shape: BoxShape.circle,
                  border: Border.all(color: _green, width: 8),
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(12),
                // 글자 크기를 키운 기기에서도 원 안에 들어가도록 필요하면 줄인다.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dialLabel,
                        style: const TextStyle(
                          color: _green,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dialValue,
                        style: const TextStyle(
                          color: _green,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (actionLabel != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          actionLabel!,
                          style: const TextStyle(
                            color: _green,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                queueText,
                style: const TextStyle(
                  color: _brown,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                requestedAt == null ? '요청 전' : '${formatTime(requestedAt!)} 신청',
                style: const TextStyle(color: _muted, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            color: _green,
            backgroundColor: _mint,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          '앱을 잠시 벗어나도 이 화면으로 돌아오면 진행 상황이 이어서 보여요.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: 14, height: 1.5),
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
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: _mint,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Icon(icon, color: _green, size: 18)
        else
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: _green,
              shape: BoxShape.circle,
            ),
          ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              color: _green,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
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
    padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
    decoration: _whiteCard,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '연결 진행 상황',
          style: TextStyle(
            color: _brown,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const _ProgressStep(
          icon: Icons.check,
          title: '상담 요청 완료',
          description: '증상과 복용 정보를 전달했어요',
          state: _StepState.done,
        ),
        const Divider(height: 1, thickness: 1, color: _divider),
        _ProgressStep(
          icon: matchingDone ? Icons.check : Icons.headset_mic_outlined,
          title: '상담 가능한 약사 확인',
          description: '가장 빠른 약사를 연결하고 있어요',
          state: matchingDone ? _StepState.done : _StepState.active,
        ),
        const Divider(height: 1, thickness: 1, color: _divider),
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
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: pending ? _pendingCircle : _mint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: pending ? _muted : _green, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: pending ? _muted : _brown,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(color: _muted, fontSize: 13),
                ),
              ],
            ),
          ),
          if (state == _StepState.active) ...[
            const SizedBox(width: 8),
            const _StatusChip(label: '진행 중'),
          ],
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
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              if (pharmacistIn)
                BoxShadow(
                  color: _yellow.withValues(alpha: 0.6 * (1 - t)),
                  spreadRadius: 8 * t,
                ),
            ],
          ),
          child: child,
        );
      },
      child: SizedBox(
        height: 60,
        child: FilledButton.icon(
          onPressed: widget.onTap,
          style: FilledButton.styleFrom(
            backgroundColor: pharmacistIn ? _brown : _yellow,
            foregroundColor: pharmacistIn ? _yellow : _brown,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          icon: Icon(
            pharmacistIn
                ? Icons.notifications_active_outlined
                : Icons.videocam_outlined,
            size: 24,
          ),
          label: Text(pharmacistIn ? '약사가 들어왔어요 — 지금 입장하기' : '화상 상담 입장하기'),
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
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    decoration: _whiteCard,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📝 상담 요약',
          style: TextStyle(
            color: _brown,
            fontSize: 16,
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
  const _PrivacyNotice({required this.preview});

  final bool preview;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _mint,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _privacyBorder),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.shield_outlined, color: _green, size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '상담 내용은 안전하게 보호돼요',
                style: TextStyle(
                  color: _green,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                preview
                    ? '현재는 화면 시연으로 상담 기록을 수집하거나 저장하지 않아요.'
                    : '상담 기록은 서비스 제공 목적 외에는 사용하지 않습니다.',
                style: const TextStyle(
                  color: _green,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _BottomActionButton extends StatelessWidget {
  const _BottomActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 56,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: _dangerBackground,
        foregroundColor: _danger,
        side: const BorderSide(color: Color(0xFFF2CFC9)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Text(label)],
      ),
    ),
  );
}
