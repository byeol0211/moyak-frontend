import 'package:flutter/material.dart';

import '../data/models.dart';

/// Read-only inventory. Purchasing and payment take place at the kiosk.
class StorePage extends StatefulWidget {
  const StorePage({required this.machineName, required this.items, super.key});

  final String machineName;
  final List<StockItem> items;

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  final _searchController = TextEditingController();
  String? _category;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StockItem> get _visibleItems {
    final query = _searchController.text.trim().toLowerCase();
    return widget.items
        .where(
          (item) =>
              (_category == null || item.category == _category) &&
              item.name.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.items
        .map((item) => item.category)
        .whereType<String>()
        .where((category) => category.isNotEmpty)
        .toSet();
    final items = _visibleItems;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F3),
      appBar: AppBar(title: const Text('자판기 재고')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text(
                widget.machineName,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '재고 상품 검색',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: '검색어 지우기',
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(_searchController.clear),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  ChoiceChip(
                    label: const Text('전체 재고'),
                    selected: _category == null,
                    onSelected: (_) => setState(() => _category = null),
                  ),
                  for (final category in categories)
                    ChoiceChip(
                      label: Text(category),
                      selected: _category == category,
                      onSelected: (_) => setState(() => _category = category),
                    ),
                ],
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        widget.items.isEmpty
                            ? '등록된 재고가 없어요.'
                            : '조건에 맞는 상품이 없어요.',
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final available = item.stock > 0;
                        return Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (item.category?.isNotEmpty == true) ...[
                                  Text(
                                    item.category!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium,
                                  ),
                                  const SizedBox(height: 4),
                                ],
                                Text(
                                  item.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  available ? '재고 ${item.stock}개' : '품절',
                                  style: TextStyle(
                                    color: available
                                        ? const Color(0xFF176B5B)
                                        : const Color(0xFF8C8B82),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 메인 화면에서 연 자판기 구매 화면: 재고를 불러온 뒤 [StorePage]를 보여준다.
class MachineStorePage extends StatefulWidget {
  const MachineStorePage({
    required this.machineName,
    required this.loadStock,
    super.key,
  });

  final String machineName;
  final Future<List<StockItem>> Function() loadStock;

  @override
  State<MachineStorePage> createState() => _MachineStorePageState();
}

class _MachineStorePageState extends State<MachineStorePage> {
  late Future<List<StockItem>> _stock = widget.loadStock();

  @override
  Widget build(BuildContext context) => FutureBuilder<List<StockItem>>(
    future: _stock,
    builder: (context, snapshot) {
      final items = snapshot.data;
      if (items != null) {
        return StorePage(machineName: widget.machineName, items: items);
      }
      final failed = snapshot.hasError;
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F3),
        appBar: AppBar(title: const Text('자판기 재고')),
        body: Center(
          child: failed
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('재고를 불러오지 못했어요.'),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _stock = widget.loadStock();
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('다시 시도'),
                    ),
                  ],
                )
              : const CircularProgressIndicator(),
        ),
      );
    },
  );
}
