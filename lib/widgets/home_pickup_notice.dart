import 'dart:async';

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../utils/format.dart';
import 'consult_header.dart';

/// 수령 전이며 아직 만료되지 않은 서버 허가서만 안내한다.
class HomePickupNotice extends StatefulWidget {
  const HomePickupNotice({
    required this.loadPermits,
    required this.onScanQr,
    required this.onOpenPermits,
    this.active = true,
    this.refreshKey,
    super.key,
  });
  final Future<List<PermitRecord>> Function() loadPermits;
  final VoidCallback onScanQr;
  final VoidCallback onOpenPermits;
  final bool active;
  final Object? refreshKey;

  @override
  State<HomePickupNotice> createState() => _HomePickupNoticeState();
}

class _HomePickupNoticeState extends State<HomePickupNotice>
    with WidgetsBindingObserver {
  List<PermitRecord>? _permits;
  bool _loading = false;
  bool _failed = false;
  int _generation = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _activate();
  }

  void _activate() {
    _timer?.cancel();
    if (!widget.active) return;
    unawaited(_refresh());
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  @override
  void didUpdateWidget(covariant HomePickupNotice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active ||
        oldWidget.refreshKey != widget.refreshKey) {
      _activate();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _activate();
    } else {
      _timer?.cancel();
    }
  }

  Future<void> _refresh() async {
    if (_loading || !widget.active) return;
    final generation = ++_generation;
    setState(() => _loading = true);
    try {
      final permits = await widget.loadPermits();
      if (!mounted || generation != _generation) return;
      setState(() {
        _permits = permits;
        _failed = false;
      });
    } catch (_) {
      if (mounted && generation == _generation) setState(() => _failed = true);
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _generation++;
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Row(
        children: [
          const Expanded(
            child: Text('수령 가능한 약을 확인하지 못했어요.', style: TextStyle(fontSize: 12)),
          ),
          TextButton(
            onPressed: _loading ? null : _refresh,
            child: const Text('재시도'),
          ),
        ],
      );
    }
    if (_permits == null) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Text('수령 가능한 약 확인 중...', style: TextStyle(fontSize: 12)),
      );
    }
    final now = DateTime.now();
    final available =
        _permits!
            .where(
              (p) =>
                  p.status == PermitStatus.available &&
                  p.expiresAt.isAfter(now),
            )
            .toList()
          ..sort((a, b) => a.expiresAt.compareTo(b.expiresAt));
    if (available.isEmpty) return const SizedBox.shrink();
    return Container(
      key: const Key('home-pickup-notice'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6D6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD54F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.medication_outlined, color: consultGreen),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '수령 가능한 약이 있어요',
                  style: TextStyle(
                    color: consultGreen,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          for (final permit in available.take(3))
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    permit.drugName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '수령 기한 · ${formatDate(permit.expiresAt.toLocal())} ${formatTime(permit.expiresAt.toLocal())}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7D6D6A),
                    ),
                  ),
                ],
              ),
            ),
          if (available.length > 3)
            Text(
              '외 ${available.length - 3}건',
              style: const TextStyle(fontSize: 12),
            ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: widget.onScanQr,
            style: FilledButton.styleFrom(backgroundColor: consultGreen),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('자판기 QR 스캔'),
          ),
          TextButton(
            onPressed: widget.onOpenPermits,
            child: const Text('전자 구매 허가서 확인'),
          ),
          const Text(
            '구매·결제와 약품 수령은 자판기에서 진행해요.',
            style: TextStyle(fontSize: 12, color: Color(0xFF7D6D6A)),
          ),
        ],
      ),
    );
  }
}
