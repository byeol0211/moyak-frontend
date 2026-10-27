/// 백엔드 연동 전까지 화면을 채우는 데모 데이터.
/// 연동할 때는 각 함수 본문만 API 호출로 바꾸면 된다(주석에 대응 API 표기).
library;

import 'models.dart';
import '../config/app_config.dart';
import 'app_session.dart';

void _requirePreview() {
  if (!AppConfig.preview.value) {
    throw StateError('서버 연결을 준비 중이에요. 화면 미리보기에서 예시 데이터를 확인할 수 있어요.');
  }
}

const _demoLatency = Duration(milliseconds: 500);

/// QR 연결처럼 자판기를 직접 고르지 않고 연결됐을 때 쓰는 자판기.
const demoConnectedMachine = VendingMachine(
  id: 'demo-3f-2',
  name: '3호관 2층 자판기',
  latitude: 37.4509,
  longitude: 126.6539,
  address: '3호관 2층 로비',
  operatingHours: '08:00 ~ 22:00',
  stockCount: 60,
  itemCount: 6,
);

/// 자판기 변경 창에서 고를 수 있는 예시 자판기들(가까운 순).
const demoNearbyMachines = [
  demoConnectedMachine,
  VendingMachine(
    id: 'demo-library-1',
    name: '중앙도서관 1층 자판기',
    latitude: 37.4521,
    longitude: 126.6548,
    address: '중앙도서관 1층 출입구 옆',
    operatingHours: '07:00 ~ 23:00',
    stockCount: 42,
    itemCount: 5,
  ),
  VendingMachine(
    id: 'demo-student-hall',
    name: '학생회관 B1 자판기',
    latitude: 37.4498,
    longitude: 126.6561,
    address: '학생회관 지하 1층',
    operatingHours: '09:00 ~ 21:00',
    itemCount: 4,
  ),
];

const _demoStock = [
  StockItem(name: '타이레놀정 500mg', stock: 12, price: 3000, category: '일반 상비'),
  StockItem(name: '판콜에이 내복액', stock: 5, price: 2600, category: '의약품'),
  StockItem(name: '훼스탈 플러스정', stock: 8, price: 3500, category: '소화제'),
  StockItem(name: '베아제정', stock: 6, price: 3000, category: '소화제'),
  StockItem(name: '생리식염수 세척용', stock: 20, price: 1500, category: '일반 위생'),
  StockItem(name: '대일밴드 혼합형', stock: 15, price: 2000, category: '일반 위생'),
];

/// 자판기 재고 조회. 연동 시: `GET /api/v1/map/machines/{id}` 의 items.
Future<List<StockItem>> fetchMachineStock(String machineId) async {
  _requirePreview();
  await Future<void>.delayed(_demoLatency);
  if (machineId == 'preview-empty') return [];
  // 자판기마다 재고가 조금씩 다르게 보이도록 id로 품절 품목을 정한다.
  final soldOutIndex = machineId.hashCode.abs() % _demoStock.length;
  return [
    for (var i = 0; i < _demoStock.length; i++)
      i == soldOutIndex
          ? StockItem(
              name: _demoStock[i].name,
              stock: 0,
              price: _demoStock[i].price,
              category: _demoStock[i].category,
            )
          : _demoStock[i],
  ];
}

/// 내 상담 내역. 연동 시: `GET /consultations?user_id=` (취소 건 제외).
Future<List<ConsultRecord>> fetchConsultHistory() async {
  _requirePreview();
  await Future<void>.delayed(_demoLatency);
  final now = DateTime.now();
  return [
    ...AppSession.instance.history,
    ConsultRecord(
      id: 'demo-consult-3',
      createdAt: now.subtract(const Duration(hours: 2)),
      status: ConsultStatus.pending,
    ),
    ConsultRecord(
      id: 'demo-consult-2',
      createdAt: now.subtract(const Duration(days: 3, hours: 4)),
      status: ConsultStatus.approved,
      direct: false,
      approvedDrugName: '타이레놀정 500mg',
      summary:
          '■ 주요 증상\n'
          '이틀 전부터 미열과 두통이 있음\n'
          '■ 약사 안내\n'
          '타이레놀정 500mg 1회 1정, 4~6시간 간격으로 복용\n'
          '하루 최대 4정을 넘기지 않기\n'
          '■ 주의사항\n'
          '음주 후 복용 금지, 3일 이상 열이 지속되면 병원 진료\n'
          '※ 상담 요약은 약사가 검토한 뒤 공개된 내용이에요.',
    ),
    ConsultRecord(
      id: 'demo-consult-1',
      createdAt: now.subtract(const Duration(days: 12, hours: 1)),
      status: ConsultStatus.rejected,
      decisionReason: '증상이 오래 지속되어 병원 진료가 먼저 필요해요.',
    ),
  ];
}

/// 전자 구매 허가서 목록. 연동 시: `GET /vending/purchases?user_id=`.
Future<List<PermitRecord>> fetchPermits() async {
  _requirePreview();
  await Future<void>.delayed(_demoLatency);
  final now = DateTime.now();
  return [
    ...AppSession.instance.permits,
    PermitRecord(
      drugName: '타이레놀정 500mg',
      status: PermitStatus.available,
      issuedAt: now.subtract(const Duration(days: 1)),
      expiresAt: now.add(const Duration(days: 1)),
      pharmacist: '김민지 약사',
    ),
    PermitRecord(
      drugName: '탁센 연질캡슐',
      status: PermitStatus.dispensed,
      issuedAt: DateTime(2024, 8, 1),
      expiresAt: DateTime(2025, 2, 1),
      pharmacist: '박진형 약사',
    ),
    PermitRecord(
      drugName: '베아제정',
      status: PermitStatus.expired,
      issuedAt: DateTime(2024, 6, 10),
      expiresAt: DateTime(2024, 12, 10),
      pharmacist: '이수진 약사',
    ),
  ];
}
