/// 화면에서 쓰는 데이터 모델. 필드 이름은 백엔드 응답(JSON)과 맞춰 두어
/// 나중에 API를 연동할 때 `fromJson`만 붙이면 되도록 했다.
library;

class VendingMachine {
  const VendingMachine({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address = '',
    this.code,
    this.operatingHours,
    this.stockCount = 0,
    this.itemCount = 0,
  });

  /// `GET /api/v1/map/machines` 응답의 items 한 건.
  factory VendingMachine.fromJson(Map<String, dynamic> json) => VendingMachine(
    id: '${json['id']}',
    name: json['name'] as String? ?? '모약 자판기',
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    address: json['address'] as String? ?? '',
    code: json['code'] as String?,
    operatingHours: json['operating_hours'] as String?,
    stockCount: (json['stock_count'] as num?)?.toInt() ?? 0,
    itemCount: (json['item_count'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String address;

  /// 자판기 코드(예: VM-001).
  final String? code;
  final String? operatingHours;
  final int stockCount;
  final int itemCount;
}

class StockItem {
  const StockItem({
    required this.name,
    required this.stock,
    this.price,
    this.category,
  });

  /// `GET /api/v1/map/machines/{id}` 응답의 items 한 건.
  factory StockItem.fromJson(Map<String, dynamic> json) => StockItem(
    name: json['item_name'] as String? ?? '${json['item_seq'] ?? '이름 없는 품목'}',
    stock: (json['stock'] as num?)?.toInt() ?? 0,
    price: (json['price'] as num?)?.toInt(),
    category: json['category'] as String?,
  );

  final String name;
  final int stock;
  final int? price;
  final String? category;
}

enum ConsultStatus { pending, approved, rejected }

class ConsultRecord {
  const ConsultRecord({
    required this.id,
    required this.createdAt,
    required this.status,
    this.direct = true,
    this.approvedDrugName,
    this.decisionReason,
    this.summary,
    this.endedAt,
  });

  final String id;
  final DateTime createdAt;
  final ConsultStatus status;

  /// 하단 "상담하기"로 바로 요청했으면 true, 챗봇 대화 후 요청했으면 false.
  final bool direct;
  final String? approvedDrugName;
  final String? decisionReason;

  /// 약사가 공개한 상담 요약. "■ 항목" 줄은 소제목, "※" 줄은 안내 문구다.
  final String? summary;
  final DateTime? endedAt;
}

enum PermitStatus { available, expired, dispensed, cancelled, unknown }

class PermitRecord {
  const PermitRecord({
    required this.drugName,
    required this.status,
    required this.issuedAt,
    required this.expiresAt,
    required this.pharmacist,
  });

  final String drugName;
  final PermitStatus status;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final String pharmacist;
}
