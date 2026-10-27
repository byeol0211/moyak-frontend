/// 자판기 관련 백엔드 API. 미리보기 모드에서는 예시 데이터를 쓴다.
library;

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api_client.dart';
import 'demo_data.dart';
import 'models.dart';

/// 자판기 품목별 재고. `GET /api/v1/map/machines/{id}` 의 items.
///
/// [client]는 테스트에서 가짜 응답을 넣을 때 쓴다.
Future<List<StockItem>> loadMachineStock(
  String machineId, {
  http.Client? client,
}) async {
  if (AppConfig.preview.value && client == null) {
    return fetchMachineStock(machineId);
  }
  final api = ApiClient(client: client);
  try {
    final data = await api.get(
      '/api/v1/map/machines/${Uri.encodeComponent(machineId)}',
    );
    return [
      for (final item in (data['items'] as List? ?? const []))
        StockItem.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  } finally {
    api.close();
  }
}

/// 기기 재탐색: [latitude], [longitude] 기준으로 가장 가까운 운영 자판기를 찾는다.
/// 서버(`GET /api/v1/map/machines?lat=&lng=`)가 가까운 순으로 정렬해 준다.
/// 주변에 자판기가 없으면 null.
Future<VendingMachine?> findNearestMachine({
  required double latitude,
  required double longitude,
  http.Client? client,
}) async {
  if (AppConfig.preview.value && client == null) {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return demoConnectedMachine;
  }
  final api = ApiClient(client: client);
  try {
    final data = await api.get(
      '/api/v1/map/machines',
      query: {'lat': '$latitude', 'lng': '$longitude'},
      // 무료 서버가 잠들어 있으면 첫 요청이 오래 걸린다.
      timeout: const Duration(seconds: 70),
    );
    for (final item in (data['items'] as List? ?? const [])) {
      final json = Map<String, dynamic>.from(item as Map);
      if (json['latitude'] is num && json['longitude'] is num) {
        return VendingMachine.fromJson(json);
      }
    }
    return null;
  } finally {
    api.close();
  }
}

/// 자판기 변경 창: [latitude], [longitude] 기준 가까운 순 운영 자판기 목록.
/// 서버(`GET /api/v1/map/machines?lat=&lng=`)가 가까운 순으로 정렬해 준다.
Future<List<VendingMachine>> loadNearbyMachines({
  required double latitude,
  required double longitude,
  http.Client? client,
}) async {
  if (AppConfig.preview.value && client == null) {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return demoNearbyMachines;
  }
  final api = ApiClient(client: client);
  try {
    final data = await api.get(
      '/api/v1/map/machines',
      query: {'lat': '$latitude', 'lng': '$longitude'},
      // 무료 서버가 잠들어 있으면 첫 요청이 오래 걸린다.
      timeout: const Duration(seconds: 70),
    );
    return [
      for (final item in (data['items'] as List? ?? const []))
        if (item is Map && item['latitude'] is num && item['longitude'] is num)
          VendingMachine.fromJson(Map<String, dynamic>.from(item)),
    ];
  } finally {
    api.close();
  }
}

/// 앱으로 자판기 QR을 스캔한 결과.
class MachineScanResult {
  const MachineScanResult({required this.machine, this.approvedDrugName});

  final VendingMachine machine;

  /// 이 자판기에서 받을 수 있는 승인된 약. 없으면 null.
  final String? approvedDrugName;
}

/// 자판기 QR 로그인. `POST /vending/scan` 으로 이 사용자를 자판기에 연결하면
/// 키오스크가 서버를 확인해 환영 화면으로 넘어간다.
///
/// QR의 machine_id는 자판기 코드(예: VM-001)라서, 지도 목록에서 같은 코드를
/// 찾아 이름을 보여준다. 찾지 못해도 연결은 성공으로 처리한다.
Future<MachineScanResult> scanMachineQr({
  required String machineId,
  required String qrToken,
  required String userId,
  http.Client? client,
}) async {
  final api = ApiClient(client: client);
  try {
    final data = await api.post(
      '/vending/scan',
      body: {'machine_id': machineId, 'qr_token': qrToken, 'user_id': userId},
      // 무료 서버가 잠들어 있으면 첫 요청이 오래 걸린다.
      timeout: const Duration(seconds: 70),
    );
    final purchase = data is Map ? data['purchase'] : null;
    VendingMachine? machine;
    try {
      final list = await api.get('/api/v1/map/machines');
      for (final item in (list['items'] as List? ?? const [])) {
        final json = Map<String, dynamic>.from(item as Map);
        if (json['code'] == machineId || '${json['id']}' == machineId) {
          machine = VendingMachine.fromJson(json);
          break;
        }
      }
    } catch (_) {
      // 자판기 이름을 못 찾아도 QR 연결 자체는 끝났다.
    }
    return MachineScanResult(
      machine:
          machine ??
          VendingMachine(
            id: machineId,
            code: machineId,
            name: machineId,
            latitude: 0,
            longitude: 0,
          ),
      approvedDrugName: purchase is Map
          ? purchase['drug_item_name'] as String?
          : null,
    );
  } finally {
    api.close();
  }
}
