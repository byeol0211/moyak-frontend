import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'consultation_platform_stub.dart'
    if (dart.library.js_interop) 'consultation_platform_web.dart';

class WorkflowPurchasePage extends StatefulWidget {
  const WorkflowPurchasePage({super.key});
  @override
  State<WorkflowPurchasePage> createState() => _WorkflowPurchasePageState();
}

class _WorkflowPurchasePageState extends State<WorkflowPurchasePage> {
  final _client = http.Client();
  final _qr = TextEditingController();
  List<dynamic> _purchases = [];
  Map<String, dynamic>? _session;
  String? _notice;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<dynamic> _api(String path, {Map<String, dynamic>? body}) async {
    final headers = {
      'Authorization': 'Bearer ${_session?['user_token']}',
      if (body != null) 'Content-Type': 'application/json',
    };
    final r =
        await (body == null
                ? _client.get(Uri.base.resolve(path), headers: headers)
                : _client.post(
                    Uri.base.resolve(path),
                    headers: headers,
                    body: jsonEncode(body),
                  ))
            .timeout(const Duration(seconds: 20));
    final data = jsonDecode(utf8.decode(r.bodyBytes));
    if (r.statusCode >= 400) throw Exception(data['detail'] ?? '요청 실패');
    return data;
  }

  Future<void> _load() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final saved = loadSession();
      if (saved == null) {
        setState(() => _notice = '상담을 시작한 사용자로 QR 연결 및 구매 허가서를 확인할 수 있습니다.');
        return;
      }
      _session = Map<String, dynamic>.from(jsonDecode(saved));
      if (_session?['user_id'] == null) {
        setState(() => _notice = '새 상담 요청 후 이용해주세요.');
        return;
      }
      final data = await _api(
        '/vending/purchases?user_id=${Uri.encodeQueryComponent(_session!['user_id'])}',
      );
      if (mounted) setState(() => _purchases = List<dynamic>.from(data));
    } catch (e) {
      if (mounted) setState(() => _notice = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _scan() async {
    if (_session?['user_id'] == null || _busy) return;
    setState(() => _busy = true);
    try {
      final qr = jsonDecode(_qr.text.trim());
      await _api(
        '/vending/scan',
        body: {
          'machine_id': qr['machine_id'],
          'qr_token': qr['qr_token'],
          'user_id': _session!['user_id'],
        },
      );
      if (mounted) {
        setState(() => _notice = '자판기 연결 완료. 키오스크 화면에서 결제·수령을 진행해주세요.');
      }
    } catch (e) {
      if (mounted) setState(() => _notice = 'QR 연결 실패: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _client.close();
    _qr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFFFBE8),
    appBar: AppBar(
      title: const Text('구매 허가서 · QR 연결'),
      actions: [
        IconButton(
          onPressed: _busy ? null : _load,
          icon: const Icon(Icons.refresh),
          tooltip: '구매 허가서 새로고침',
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          '로컬 통합 시연 · 실제 결제와 자판기 하드웨어 동작은 모의 처리합니다.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: _session?['user_id'] == null
                  ? null
                  : () => openWorkflowPage('/scan'),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('카메라로 QR 스캔'),
            ),
            OutlinedButton(
              onPressed: () => openWorkflowPage('/kiosk/start/'),
              child: const Text('키오스크 시연 열기'),
            ),
            OutlinedButton(
              onPressed: () => openWorkflowPage('/kiosk/otc-list/'),
              child: const Text('의약외품 즉시 구매'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('같은 PC에서 시연할 때는 키오스크 QR 연결 화면의 “QR 내용 복사”를 이용하세요.'),
        const SizedBox(height: 8),
        TextField(
          controller: _qr,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'QR 내용 붙여넣기',
            border: OutlineInputBorder(),
          ),
        ),
        TextButton(
          onPressed: _busy || _session?['user_id'] == null ? null : _scan,
          child: const Text('QR로 자판기 연결'),
        ),
        if (_busy) const LinearProgressIndicator(),
        if (_notice != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(_notice!),
          ),
        const Divider(),
        const Text(
          '내 구매 허가서',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        if (_purchases.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('아직 약사가 승인한 구매 건이 없습니다.'),
          ),
        for (final p in _purchases)
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.verified_outlined,
                color: Color(0xFFF1C744),
              ),
              title: Text(p['drug_item_name']),
              subtitle: Text(
                '상태: ${const {'pending': '수령 대기', 'dispensed': '수령 완료', 'expired': '유효기간 만료', 'cancelled': '취소'}[p['status']] ?? p['status']} · ${p['price'] == null ? '가격 미지정' : '${p['price']}원'}\n${p['paid_at'] == null ? '미결제' : '결제 완료'}',
              ),
            ),
          ),
      ],
    ),
  );
}
