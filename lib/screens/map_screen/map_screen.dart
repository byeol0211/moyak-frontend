import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

import '../../data/demo_data.dart';
import '../../data/models.dart';
import '../../utils/format.dart';
import '../../widgets/app_status_bar.dart';

const _mapCanvas = Color(0xFFF2EBDD);
const _mapBox = Color(0xFFE9E1D0);
const _mapInk = Color(0xFF3E2723);
const _mapMuted = Color(0xFF7D6D6A);
const _mapYellow = Color(0xFFFFD54F);
const _mapShadow = [
  BoxShadow(color: Color(0x143E2723), blurRadius: 16, offset: Offset(0, 8)),
];

final _defaultCenter = LatLng(37.4509, 126.6539);

/// 내 주변 자판기: 지도 + 가까운 자판기 목록 → 자판기 재고 상세 → "이 자판기 선택".
class MapScreen extends StatefulWidget {
  const MapScreen({
    required this.selectedMachineId,
    required this.onSelectMachine,
    required this.onUnselectMachine,
    this.client,
    super.key,
  });

  final String? selectedMachineId;
  final ValueChanged<VendingMachine> onSelectMachine;
  final VoidCallback onUnselectMachine;
  final http.Client? client;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  KakaoMapController? _map;
  late final http.Client _client = widget.client ?? http.Client();
  List<VendingMachine> _machines = [];
  final _distances = <String, double>{};
  VendingMachine? _detail;
  Future<List<StockItem>>? _detailStock;
  String? _error;
  bool _loading = true;

  // 위치 권한 연동 전이라 거리는 기본 위치 기준으로 계산한다.
  LatLng get _origin => _defaultCenter;

  LatLng _point(VendingMachine m) => LatLng(m.latitude, m.longitude);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      const apiBase = String.fromEnvironment('API_BASE_URL');
      final base = apiBase.isEmpty ? Uri.base : Uri.parse(apiBase);
      final r = await _client
          .get(base.resolve('/api/v1/map/machines'))
          .timeout(const Duration(seconds: 20));
      final data = jsonDecode(utf8.decode(r.bodyBytes));
      if (r.statusCode != 200) throw Exception(data['detail'] ?? '자판기 조회 실패');
      final machines = (data['items'] as List)
          .map((m) => Map<String, dynamic>.from(m))
          .where(
            (m) =>
                m['latitude'] is num &&
                m['longitude'] is num &&
                (m['latitude'] as num).abs() <= 90 &&
                (m['longitude'] as num).abs() <= 180,
          )
          .map(VendingMachine.fromJson)
          .toList();
      for (final m in machines) {
        _distances[m.id] = _distanceM(_origin, _point(m));
      }
      machines.sort((a, b) => _distances[a.id]!.compareTo(_distances[b.id]!));
      if (!mounted) return;
      setState(() => _machines = machines);
      if (machines.isNotEmpty) _map?.panTo(_point(machines.first));
    } catch (e) {
      if (mounted) {
        setState(() => _error = '자판기 목록을 불러오지 못했어요. 잠시 후 다시 시도해주세요.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openDetail(VendingMachine machine) {
    setState(() {
      _detail = machine;
      _detailStock = fetchMachineStock(machine.id);
    });
    _map?.panTo(_point(machine));
  }

  void _closeDetail() => setState(() {
    _detail = null;
    _detailStock = null;
  });

  @override
  void dispose() {
    if (widget.client == null) _client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarColor: _mapCanvas,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
    child: ColoredBox(
      color: _mapCanvas,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppStatusBar(color: _mapInk),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '내 주변 자판기',
                    style: TextStyle(
                      color: _mapInk,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _loading
                        ? '위치를 확인하고 있어요...'
                        : '위치 권한이 없어 기본 위치 기준 거리로 보여드려요',
                    style: const TextStyle(color: _mapMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _MapBox(
                machines: _machines,
                selectedId: widget.selectedMachineId,
                focusedId: _detail?.id,
                onMapCreated: (controller) => _map = controller,
                onTapMachine: _openDetail,
                onLocate: () => _map?.panTo(_origin),
                center: _machines.isEmpty
                    ? _defaultCenter
                    : _point(_machines.first),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: _detail == null
                    ? _MachineList(
                        machines: _machines,
                        distances: _distances,
                        selectedId: widget.selectedMachineId,
                        loading: _loading,
                        error: _error,
                        onRetry: _load,
                        onTap: _openDetail,
                      )
                    : _MachineDetail(
                        machine: _detail!,
                        distance: _distances[_detail!.id],
                        stock: _detailStock!,
                        selected: _detail!.id == widget.selectedMachineId,
                        onBack: _closeDetail,
                        onSelect: () => widget.onSelectMachine(_detail!),
                        onUnselect: widget.onUnselectMachine,
                      ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

double _distanceM(LatLng a, LatLng b) {
  const r = 6371000.0;
  const rad = math.pi / 180;
  final dLat = (b.latitude - a.latitude) * rad;
  final dLng = (b.longitude - a.longitude) * rad;
  final h =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(a.latitude * rad) *
          math.cos(b.latitude * rad) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * r * math.asin(math.sqrt(h));
}

/// 예: 350m · 도보 5분 / 1.2km · 도보 18분 / 12.4km (도보 분당 약 67m)
String _formatDistance(double? meters) {
  if (meters == null) return '';
  final m = meters.round();
  if (m < 1000) return '${m}m · 도보 ${math.max(1, (m / 67).round())}분';
  if (m < 2000) {
    return '${(m / 1000).toStringAsFixed(1)}km · 도보 ${(m / 67).round()}분';
  }
  return m < 100000
      ? '${(m / 1000).toStringAsFixed(1)}km'
      : '${(m / 1000).round()}km';
}

class _MapBox extends StatelessWidget {
  const _MapBox({
    required this.machines,
    required this.selectedId,
    required this.focusedId,
    required this.onMapCreated,
    required this.onTapMachine,
    required this.onLocate,
    required this.center,
  });

  final List<VendingMachine> machines;
  final String? selectedId;
  final String? focusedId;
  final ValueChanged<KakaoMapController> onMapCreated;
  final ValueChanged<VendingMachine> onTapMachine;
  final VoidCallback onLocate;
  final LatLng center;

  @override
  Widget build(BuildContext context) => Container(
    height: 286,
    decoration: BoxDecoration(
      color: _mapBox,
      borderRadius: BorderRadius.circular(24),
      boxShadow: _mapShadow,
    ),
    clipBehavior: Clip.antiAlias,
    child: AuthRepository.isInitialized
        ? Stack(
            fit: StackFit.expand,
            children: [
              KakaoMap(
                center: center,
                currentLevel: 4,
                onMapCreated: onMapCreated,
                widgetOverlays: [
                  for (var i = 0; i < machines.length; i++)
                    KakaoMapWidgetOverlay(
                      id: machines[i].id,
                      position: LatLng(
                        machines[i].latitude,
                        machines[i].longitude,
                      ),
                      anchor: Alignment.bottomCenter,
                      child: _NumberPin(
                        number: i + 1,
                        machine: machines[i],
                        active: machines[i].id == selectedId,
                        focused: machines[i].id == focusedId,
                        onTap: () => onTapMachine(machines[i]),
                      ),
                    ),
                ],
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: KakaoMapPointerInterceptor(
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 3,
                    shadowColor: const Color(0x333E2723),
                    child: InkWell(
                      onTap: onLocate,
                      customBorder: const CircleBorder(),
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(
                          Icons.my_location,
                          color: _mapInk,
                          size: 20,
                          semanticLabel: '내 위치로',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )
        : const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '🗺️ 지도 준비 중\n',
                      style: TextStyle(
                        color: _mapInk,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 2,
                      ),
                    ),
                    TextSpan(
                      text: '카카오 지도 키가 아직 설정되지 않았어요.\n아래 목록에서 자판기를 선택할 수 있어요.',
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: TextStyle(color: _mapMuted, fontSize: 13, height: 1.5),
              ),
            ),
          ),
  );
}

/// 목록 번호와 같은 숫자 핀. 상세를 보고 있는 자판기만 이름까지 표시한다.
class _NumberPin extends StatelessWidget {
  const _NumberPin({
    required this.number,
    required this.machine,
    required this.active,
    required this.focused,
    required this.onTap,
  });

  final int number;
  final VendingMachine machine;
  final bool active;
  final bool focused;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final soldOut = machine.stockCount == 0;
    final (background, foreground) = active
        ? (_mapInk, _mapYellow)
        : soldOut
        ? (const Color(0xFFD7CCC8), const Color(0xFF6D5D58))
        : (_mapYellow, _mapInk);
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: machine.name,
        child: Container(
          height: 30,
          constraints: const BoxConstraints(minWidth: 30),
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x4D3E2723),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            focused
                ? '$number ${machine.name.replaceFirst('모약 자판기 ', '')}'
                : '$number',
            style: TextStyle(
              color: foreground,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _MachineList extends StatelessWidget {
  const _MachineList({
    required this.machines,
    required this.distances,
    required this.selectedId,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onTap,
  });

  final List<VendingMachine> machines;
  final Map<String, double> distances;
  final String? selectedId;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final ValueChanged<VendingMachine> onTap;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              loading ? '가까운 자판기' : '가까운 자판기 ${machines.length}곳',
              style: const TextStyle(
                color: _mapInk,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Text(
            '재고는 조회 시점 기준',
            style: TextStyle(color: _mapMuted, fontSize: 11),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Expanded(
        child: switch ((loading, error, machines.isEmpty)) {
          (true, _, _) => const _EmptyText('자판기를 불러오는 중...'),
          (_, final String message, _) => Column(
            children: [
              _EmptyText(message),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF8B6914),
                ),
                child: const Text('다시 불러오기'),
              ),
            ],
          ),
          (_, _, true) => const _EmptyText('주변에 운영 중인 자판기가 없어요.'),
          _ => ListView.separated(
            padding: const EdgeInsets.only(bottom: 4),
            itemCount: machines.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _MachineCard(
              number: index + 1,
              machine: machines[index],
              distance: distances[machines[index].id],
              selected: machines[index].id == selectedId,
              onTap: () => onTap(machines[index]),
            ),
          ),
        },
      ),
    ],
  );
}

class _MachineCard extends StatelessWidget {
  const _MachineCard({
    required this.number,
    required this.machine,
    required this.distance,
    required this.selected,
    required this.onTap,
  });

  final int number;
  final VendingMachine machine;
  final double? distance;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final distanceLabel = _formatDistance(distance);
    final hours = machine.operatingHours ?? '운영시간 정보 없음';
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: _mapShadow,
      ),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: selected ? _mapYellow : Colors.transparent,
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF8E1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      color: _mapInk,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        machine.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _mapInk,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        distanceLabel.isEmpty
                            ? hours
                            : '$distanceLabel · $hours',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _mapMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _StockBadge(stockCount: machine.stockCount),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.stockCount});

  final int stockCount;

  @override
  Widget build(BuildContext context) {
    final (label, background, foreground) = stockCount == 0
        ? ('품절', const Color(0xFFF5F5F3), const Color(0xFF9E8F8A))
        : stockCount < 10
        ? ('재고 적음', const Color(0xFFFFF3E0), const Color(0xFFEF6C00))
        : ('재고 있음', const Color(0xFFE8F5E9), const Color(0xFF2E7D32));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MachineDetail extends StatelessWidget {
  const _MachineDetail({
    required this.machine,
    required this.distance,
    required this.stock,
    required this.selected,
    required this.onBack,
    required this.onSelect,
    required this.onUnselect,
  });

  final VendingMachine machine;
  final double? distance;
  final Future<List<StockItem>> stock;
  final bool selected;
  final VoidCallback onBack;
  final VoidCallback onSelect;
  final VoidCallback onUnselect;

  @override
  Widget build(BuildContext context) {
    final distanceLabel = _formatDistance(distance);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: _mapShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      machine.name,
                      style: const TextStyle(
                        color: _mapInk,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (machine.address.isNotEmpty) machine.address,
                        [
                          if (distanceLabel.isNotEmpty) distanceLabel,
                          '운영 ${machine.operatingHours ?? '정보 없음'}',
                        ].join(' · '),
                      ].join('\n'),
                      style: const TextStyle(
                        color: _mapMuted,
                        fontSize: 12,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onBack,
                style: TextButton.styleFrom(
                  foregroundColor: _mapMuted,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('목록 ›'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF0E8DA)),
          Expanded(
            child: FutureBuilder<List<StockItem>>(
              future: stock,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const _EmptyText('재고를 불러오지 못했어요.');
                }
                final items = snapshot.data;
                if (items == null) return const _EmptyText('재고를 불러오는 중...');
                if (items.isEmpty) return const _EmptyText('등록된 재고가 없어요.');
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: Color(0xFFF7F1E6)),
                  itemBuilder: (context, index) =>
                      _StockRow(item: items[index]),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            child: selected
                ? OutlinedButton(
                    onPressed: onUnselect,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF8B6914),
                      side: const BorderSide(color: _mapYellow, width: 1.5),
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: const Text('선택됨 ✓ · 선택 해제'),
                  )
                : FilledButton(
                    onPressed: onSelect,
                    style: FilledButton.styleFrom(
                      backgroundColor: _mapYellow,
                      foregroundColor: _mapInk,
                      shape: const StadiumBorder(),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: const Text('이 자판기 선택'),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StockRow extends StatelessWidget {
  const _StockRow({required this.item});

  final StockItem item;

  @override
  Widget build(BuildContext context) {
    final price = item.price;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                text: item.name,
                children: [
                  if (price != null)
                    TextSpan(
                      text: ' · ${formatPrice(price)}',
                      style: const TextStyle(
                        color: _mapMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _mapInk,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.stock > 0 ? '${item.stock}개' : '품절',
            style: TextStyle(
              color: item.stock > 0
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFB0A29D),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 30),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(color: _mapMuted, fontSize: 13),
    ),
  );
}
