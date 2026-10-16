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
