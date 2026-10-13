import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

const _mapCanvas = Color(0xFFF1EEE5);
const _mapInk = Color(0xFF3E2723);
const _mapMuted = Color(0xFF8D7F79);
const _mapYellow = Color(0xFFFFD54F);

const _defaultCenter = LatLng(37.4509, 126.6539);

class MapScreen extends StatefulWidget {
  const MapScreen({required this.onOpenStore, this.client, super.key});

  final VoidCallback onOpenStore;
  final http.Client? client;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _map = MapController();
  late final http.Client _client = widget.client ?? http.Client();
  final _search = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  Map<String, dynamic>? _selected;
  String? _error;
  String _source = '';
  bool _loading = true, _ready = false, _limited = false;

  LatLng _point(Map<String, dynamic> m) => LatLng(
    (m['latitude'] as num).toDouble(),
    (m['longitude'] as num).toDouble(),
  );

  List<Map<String, dynamic>> get _filtered {
    final query = _search.text.trim().toLowerCase();
    return _items
        .where(
          (m) => '${m['name']} ${m['address']}'.toLowerCase().contains(query),
        )
        .toList();
  }

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
      if (!mounted) return;
      setState(() {
        _items = (data['items'] as List)
            .map((m) => Map<String, dynamic>.from(m))
            .where(
              (m) =>
                  m['latitude'] is num &&
                  m['longitude'] is num &&
                  (m['latitude'] as num).abs() <= 90 &&
                  (m['longitude'] as num).abs() <= 180,
            )
            .toList();
        _source = data['source'] == 'supabase' ? '등록 자판기' : '로컬 시연 데이터';
        _limited = data['truncated'] == true;
        _selected = _filtered.isEmpty ? null : _filtered.first;
      });
      if (_ready && _selected != null) _map.move(_point(_selected!), 16);
    } catch (e) {
      if (mounted) {
        setState(() => _error = '자판기 위치를 불러오지 못했습니다. 잠시 후 다시 시도해주세요.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _select(Map<String, dynamic> item) {
    setState(() => _selected = item);
    if (_ready) _map.move(_point(item), 16);
  }

  @override
  void dispose() {
    if (widget.client == null) _client.close();
    _map.dispose();
    _search.dispose();
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
        child: Stack(
          fit: StackFit.expand,
          children: [
            FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCenter: _selected == null
                    ? _defaultCenter
                    : _point(_selected!),
                initialZoom: 16,
                minZoom: 3,
                maxZoom: 19,
                onMapReady: () => _ready = true,
              ),
              children: [
                TileLayer(
                  tileDisplay: const TileDisplay.instantaneous(),
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.moyak.app',
                  maxNativeZoom: 19,
                  panBuffer: 0,
                ),
                MarkerLayer(
                  markers: [
                    for (final m in _filtered)
                      m['id'] == _selected?['id']
                          ? Marker(
                              point: _point(m),
                              width: 140,
                              height: 96,
                              alignment: Alignment.topCenter,
                              child: _SelectedVendingMarker(
                                label: m['name'] as String,
                              ),
                            )
                          : Marker(
                              point: _point(m),
                              width: 80,
                              height: 60,
                              alignment: Alignment.topCenter,
                              child: GestureDetector(
                                onTap: () => _select(m),
                                child: Tooltip(
                                  message: m['name'] as String,
                                  child: const _VendingMarker(),
                                ),
                              ),
                            ),
                  ],
                ),
                RichAttributionWidget(
                  alignment: AttributionAlignment.bottomLeft,
                  attributions: [
                    TextSourceAttribution(
                      'OpenStreetMap contributors',
                      onTap: () => launchUrl(
                        Uri.parse('https://www.openstreetmap.org/copyright'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SearchBar(
                    controller: _search,
                    loading: _loading,
                    onRefresh: _load,
                    onChanged: (_) => setState(() {
                      if (!_filtered.any((m) => m['id'] == _selected?['id'])) {
                        _selected = null;
                      }
                    }),
                    onSubmitted: (_) {
                      if (_filtered.isNotEmpty) _select(_filtered.first);
                    },
                  ),
                  if (_loading) ...[
                    const SizedBox(height: 8),
                    const LinearProgressIndicator(
                      color: _mapYellow,
                      backgroundColor: Color(0xFFFFF6D8),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    _MapNotice(text: _error!, error: true),
                  ] else if (!_loading) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _MapNotice(
                        text:
                            '$_source ${_filtered.length}곳${_limited ? ' · 최대 500곳 표시' : ''}',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_selected != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _StoreSheet(
                  machine: _selected!,
                  onOpenStore: widget.onOpenStore,
                ),
              )
            else if (!_loading && _error == null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: _MapNotice(
                  text: _items.isEmpty
                      ? '위치가 등록된 운영 자판기가 없습니다.'
                      : '검색 결과를 선택하거나 다른 이름으로 검색해주세요.',
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.loading,
    required this.onRefresh,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool loading;
  final VoidCallback onRefresh;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 3)),
      ],
    ),
    child: TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search, color: _mapMuted),
        suffixIcon: IconButton(
          tooltip: '자판기 새로고침',
          onPressed: loading ? null : onRefresh,
          icon: const Icon(Icons.refresh, color: _mapMuted),
        ),
        hintText: '가까운 모약 자판기 검색',
        hintStyle: const TextStyle(color: _mapMuted, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );
}

class _MapNotice extends StatelessWidget {
  const _MapNotice({required this.text, this.error = false});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: error ? const Color(0xFFFFF1EE) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(color: Color(0x10000000), blurRadius: 6, offset: Offset(0, 2)),
      ],
    ),
    child: Text(
      text,
      style: TextStyle(
        color: error ? const Color(0xFFD84B2F) : _mapMuted,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _VendingMarker extends StatelessWidget {
  const _VendingMarker();

  @override
  Widget build(BuildContext context) => const Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      CircleAvatar(
        radius: 20,
        backgroundColor: Color(0xFFD7D7D3),
        child: Icon(Icons.dns_outlined, color: Color(0xFF737773), size: 23),
      ),
      SizedBox(height: 3),
      Text(
        'VENDING MACHINE',
        style: TextStyle(
          color: Color(0xFF777B78),
          fontSize: 7,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

class _SelectedVendingMarker extends StatelessWidget {
  const _SelectedVendingMarker({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _mapYellow,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, color: Colors.white, size: 12),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
      const Icon(Icons.arrow_drop_down, color: _mapYellow, size: 18),
      const _VendingMarker(),
    ],
  );
}

class _StoreSheet extends StatelessWidget {
  const _StoreSheet({required this.machine, required this.onOpenStore});

  final Map<String, dynamic> machine;
  final VoidCallback onOpenStore;

  @override
  Widget build(BuildContext context) {
    final itemCount = machine['item_count'] as num? ?? 0;
    final hours = machine['operating_hours'];
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9E7),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            machine['name'] as String,
            style: const TextStyle(
              color: _mapInk,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            machine['address'] as String? ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _mapMuted, fontSize: 12),
          ),
          if (hours != null) ...[
            const SizedBox(height: 3),
            Text(
              '운영 시간 · $hours',
              style: const TextStyle(color: _mapMuted, fontSize: 12),
            ),
          ],
          const Divider(height: 28, color: Color(0xFFEDE9E7)),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '실시간 재고',
                      style: TextStyle(color: _mapMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      itemCount == 0
                          ? '등록된 재고 정보 없음'
                          : '재고 ${machine['stock_count']}개 · $itemCount개 품목',
                      style: TextStyle(
                        color: itemCount == 0
                            ? _mapMuted
                            : const Color(0xFF00B957),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 44,
                child: FilledButton(
                  onPressed: onOpenStore,
                  style: FilledButton.styleFrom(
                    backgroundColor: _mapYellow,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('재고 상품보기'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '재고는 새로고침 시점의 정보입니다.',
            style: TextStyle(color: _mapMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
