import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_status_bar.dart';
import '../widgets/app_bottom_navigation.dart';
import '../widgets/primary_button.dart';
import '../widgets/feature_notice.dart';

class InventoryRequestPage extends StatefulWidget {
  const InventoryRequestPage({required this.onTabSelected, super.key});

  final ValueChanged<int> onTabSelected;

  @override
  State<InventoryRequestPage> createState() => _InventoryRequestPageState();
}

class _InventoryRequestPageState extends State<InventoryRequestPage> {
  final _searchController = TextEditingController();
  final _selectedMedicines = <String>{};
  String _selectedVendingMachine = '3호관 2층 자판기';

  static const _medicines = [
    _InventoryMedicine('어린이 부루펜시럽', '해열 진통제'),
    _InventoryMedicine('겔포스엠 현탁액', '제산 소화제'),
    _InventoryMedicine('이지엔6 프로 연질캡슐', '소염 진통제'),
  ];

  List<_InventoryMedicine> get _filteredMedicines {
    final query = _searchController.text.trim();
    if (query.isEmpty) return _medicines;
    return _medicines
        .where((medicine) => medicine.name.contains(query))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (_selectedMedicines.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('신청할 약품을 선택해주세요.')));
      return;
    }

    showFeatureNotice(context, '재고 신청은 준비 중이에요. 아직 서버로 전송되지 않습니다.');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F5F5),
    body: SafeArea(
      child: Column(
        children: [
          const AppStatusBar(),
          SizedBox(
            height: 44,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.chevron_left, size: 23),
                ),
                const Expanded(
                  child: Text(
                    '재고 신청',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              children: [
                const _InventoryFieldLabel('자판기 선택'),
                const SizedBox(height: 8),
                Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFECE7E3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedVendingMachine,
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: mutedInk,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: '3호관 2층 자판기',
                          child: Row(
                            children: [
                              Icon(
                                Icons.grid_view,
                                color: brandYellow,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                '3호관 2층 자판기',
                                style: TextStyle(
                                  color: ink,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: '학생회관 1층 자판기',
                          child: Text('학생회관 1층 자판기'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedVendingMachine = value);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const _InventoryFieldLabel('신청할 약품 검색'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 42,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(color: ink, fontSize: 12),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, size: 18),
                      prefixIconColor: mutedInk,
                      hintText: '약품명을 입력하세요 (예: 타이레놀)',
                      hintStyle: const TextStyle(color: mutedInk, fontSize: 11),
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFECE7E3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFECE7E3)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '자판기 품절 인기 의약품',
                  style: TextStyle(
                    color: mutedInk,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                for (final medicine in _filteredMedicines) ...[
                  _InventoryMedicineTile(
                    medicine: medicine,
                    selected: _selectedMedicines.contains(medicine.name),
                    onChanged: (value) => setState(
                      () => value
                          ? _selectedMedicines.add(medicine.name)
                          : _selectedMedicines.remove(medicine.name),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 10),
            child: SizedBox(
              width: double.infinity,
              height: 46,
              child: PrimaryButton(label: '신청하기', onPressed: _submitRequest),
            ),
          ),
          AppBottomNavigation(
            selectedIndex: 4,
            onSelected: widget.onTabSelected,
          ),
        ],
      ),
    ),
  );
}

class _InventoryMedicine {
  const _InventoryMedicine(this.name, this.category);

  final String name;
  final String category;
}

class _InventoryFieldLabel extends StatelessWidget {
  const _InventoryFieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: ink,
      fontSize: 11,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _InventoryMedicineTile extends StatelessWidget {
  const _InventoryMedicineTile({
    required this.medicine,
    required this.selected,
    required this.onChanged,
  });

  final _InventoryMedicine medicine;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => onChanged(!selected),
    borderRadius: BorderRadius.circular(12),
    child: Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFECE7E3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine.name,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  medicine.category,
                  style: const TextStyle(color: mutedInk, fontSize: 9),
                ),
              ],
            ),
          ),
          const Text(
            '남은 수량 0개',
            style: TextStyle(color: Colors.red, fontSize: 9),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: selected,
              onChanged: (value) => onChanged(value ?? false),
              side: const BorderSide(color: brandYellow, width: 1.2),
              activeColor: brandYellow,
              checkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    ),
  );
}
