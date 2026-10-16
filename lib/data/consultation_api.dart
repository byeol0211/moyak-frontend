/// 약사 상담·전자 구매 허가서 백엔드 API (`/consultations`, `/vending/purchases`).
library;

import 'package:http/http.dart' as http;

import 'api_client.dart';
import 'models.dart';

/// 상담 한 건의 서버 상태.
class ConsultationSnapshot {
  const ConsultationSnapshot({
    required this.record,
    required this.raw,
    this.cancelled = false,
  });

  final ConsultRecord record;

  /// 화상방 정보(`room_url`) 등을 꺼낼 때 쓰는 원본 응답.
  final Map<String, dynamic> raw;
  final bool cancelled;

  String get id => record.id;
  String? get roomUrl => raw['room_url'] as String?;
  bool get finished => cancelled || record.endedAt != null;
}

class ConsultationApi {
  ConsultationApi({http.Client? client}) : _api = ApiClient(client: client);

  final ApiClient _api;

  /// 서버가 직접 상담(챗봇 대화 없음)에 채워 넣는 문구.
  static const _directPrefix = '직접 상담 요청';

  static ConsultationSnapshot parse(Map<String, dynamic> json) {
    final status = json['status'];
    return ConsultationSnapshot(
      raw: json,
      cancelled: status == 'cancelled',
      record: ConsultRecord(
        id: '${json['id']}',
        createdAt: parseServerTime(json['created_at']) ?? DateTime.now(),
        status: switch (status) {
          'approved' => ConsultStatus.approved,
          'rejected' => ConsultStatus.rejected,
          _ => ConsultStatus.pending,
        },
        direct:
            (json['chat_summary'] as String? ?? '').isEmpty ||
            (json['chat_summary'] as String).startsWith(_directPrefix),
        approvedDrugName: json['approved_drug_name'] as String?,
        decisionReason: json['decision_reason'] as String?,
        summary: json['summary'] as String?,
        endedAt: parseServerTime(json['ended_at']),
      ),
    );
  }

  /// 진행 중인 상담이 있으면 그걸 이어서 쓰고, 없으면 새로 요청한다.
  /// 챗봇에서 왔으면 대화 내용([chatSummary])을 약사에게 전달한다.
  Future<ConsultationSnapshot> findOrCreate({
    required String userId,
    String chatSummary = '',
  }) async {
    // 무료 서버가 잠들어 있으면 첫 요청이 1분쯤 걸려서 넉넉히 기다린다.
    const wakeTimeout = Duration(seconds: 70);
    final pending = await _api.get(
      '/consultations',
      query: {'status': 'pending', 'user_id': userId},
      timeout: wakeTimeout,
    );
    if (pending is List && pending.isNotEmpty) {
      final open = pending
          .map((item) => parse(Map<String, dynamic>.from(item as Map)))
          .where((snapshot) => !snapshot.finished)
          .toList();
      if (open.isNotEmpty) return open.first;
    }
    final created = await _api.post(
      '/consultations',
      body: {
        'user_id': userId,
        if (chatSummary.trim().isNotEmpty) 'chat_summary': chatSummary,
      },
      timeout: wakeTimeout,
    );
    return parse(Map<String, dynamic>.from(created as Map));
  }

  Future<ConsultationSnapshot> get(String id) async => parse(
    Map<String, dynamic>.from(
      await _api.get('/consultations/${Uri.encodeComponent(id)}') as Map,
    ),
  );

  Future<ConsultationSnapshot> cancel(String id) async => parse(
    Map<String, dynamic>.from(
      await _api.post('/consultations/${Uri.encodeComponent(id)}/cancel')
          as Map,
    ),
  );

  /// 약사가 화상방에 들어와 있는지. 서버가 확인할 수 없으면 null.
  Future<bool?> pharmacistInRoom(String id) async {
    final data = await _api.get(
      '/consultations/${Uri.encodeComponent(id)}/presence',
      timeout: const Duration(seconds: 10),
    );
    if (data is! Map || data['available'] != true) return null;
    return data['pharmacist_in_room'] == true;
  }

  /// 내 상담 내역(최신순). 취소한 상담은 보여주지 않는다.
  Future<List<ConsultRecord>> history(String userId) async {
    final data = await _api.get('/consultations', query: {'user_id': userId});
    return [
      for (final item in data as List)
        parse(Map<String, dynamic>.from(item as Map)),
    ].where((s) => !s.cancelled).map((s) => s.record).toList();
  }

  /// 전자 구매 허가서 목록.
  Future<List<PermitRecord>> permits(String userId) async {
    final data = await _api.get(
      '/vending/purchases',
      query: {'user_id': userId},
    );
    return [
      for (final item in data as List)
        if (item is Map)
          PermitRecord(
            drugName: item['drug_item_name'] as String? ?? '-',
            status: switch (item['status']) {
              'expired' => PermitStatus.expired,
              'dispensed' => PermitStatus.dispensed,
              'cancelled' => PermitStatus.cancelled,
              _ => PermitStatus.available,
            },
            issuedAt: parseServerTime(item['created_at']) ?? DateTime.now(),
            expiresAt: parseServerTime(item['expires_at']) ?? DateTime.now(),
            pharmacist: item['approved_by'] as String? ?? '-',
          ),
    ];
  }

  void close() => _api.close();
}
