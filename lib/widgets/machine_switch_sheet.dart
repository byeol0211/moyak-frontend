import 'package:flutter/material.dart';

import '../data/models.dart';

const _darkBrown = Color(0xFF3E2723);
const _secondaryBrown = Color(0xFF8D7F79);
const _brandYellow = Color(0xFFFFD54F);
const _softYellow = Color(0xFFFFF6D6);
const _green = Color(0xFF13B965);
const _greenBackground = Color(0xFFE8FBF0);
const _line = Color(0xFFF0ECE7);

/// 메인 화면 '선택됨' 배지를 눌렀을 때: 주변 자판기 중 다른 자판기를 고른다.
/// 고른 자판기를 돌려주고, 닫거나 지금 자판기를 고르면 null.
Future<VendingMachine?> showMachineSwitchSheet(
  BuildContext context, {
  required String currentMachineId,
  required Future<List<VendingMachine>> Function() loadMachines,
}) => showModalBottomSheet<VendingMachine>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.white,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  builder: (_) => MachineSwitchSheet(
    currentMachineId: currentMachineId,
    loadMachines: loadMachines,
  ),
);

class MachineSwitchSheet extends StatefulWidget {
  const MachineSwitchSheet({
    required this.currentMachineId,
    required this.loadMachines,
    super.key,
  });

  final String currentMachineId;
  final Future<List<VendingMachine>> Function() loadMachines;

  @override
  State<MachineSwitchSheet> createState() => _MachineSwitchSheetState();
}

class _MachineSwitchSheetState extends State<MachineSwitchSheet> {
  late Future<List<VendingMachine>> _machines = widget.loadMachines();

  void _retry() {
    setState(() {
      _machines = widget.loadMachines();
    });
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2DCD5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            '연결할 자판기 변경',
            style: TextStyle(
              color: _darkBrown,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '가까운 순으로 보여드려요. 이용할 자판기를 눌러 바꿔주세요.',
            style: TextStyle(color: _secondaryBrown, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.5,
            ),
            child: FutureBuilder<List<VendingMachine>>(
              future: _machines,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _SheetMessage(
                    text: '자판기 목록을 불러오지 못했어요.',
                    action: TextButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('다시 시도'),
                      style: TextButton.styleFrom(foregroundColor: _darkBrown),
                    ),
                  );
                }
                final machines = snapshot.data;
                if (machines == null) {
                  return const _SheetMessage(
                    text: '주변 자판기를 찾고 있어요...',
                    loading: true,
                  );
                }
                if (machines.isEmpty) {
                  return const _SheetMessage(text: '주변에 연결할 자판기가 없어요.');
                }
                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: machines.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final machine = machines[index];
                    final current = machine.id == widget.currentMachineId;
                    return _MachineTile(
                      machine: machine,
                      current: current,
                      onTap: () =>
                          Navigator.pop(context, current ? null : machine),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: _secondaryBrown,
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('닫기'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _MachineTile extends StatelessWidget {
  const _MachineTile({
    required this.machine,
    required this.current,
    required this.onTap,
  });

  final VendingMachine machine;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (machine.address.isNotEmpty) machine.address,
      if (machine.operatingHours?.isNotEmpty == true) machine.operatingHours!,
    ].join(' · ');
    return Material(
      color: current ? _greenBackground : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: current ? const Color(0xFF8AE0AE) : _line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: current ? Colors.white : _softYellow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.storefront_outlined,
                  color: current ? _green : const Color(0xFFB98A00),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      machine.name,
                      style: const TextStyle(
                        color: _darkBrown,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        details,
                        style: const TextStyle(
                          color: _secondaryBrown,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (current)
                const Text(
                  '연결 중',
                  style: TextStyle(
                    color: _green,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                )
              else
                const Icon(Icons.chevron_right, color: _secondaryBrown),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetMessage extends StatelessWidget {
  const _SheetMessage({required this.text, this.loading = false, this.action});

  final String text;
  final bool loading;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 28),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (loading) ...[
          const SizedBox.square(
            dimension: 28,
            child: CircularProgressIndicator(
              color: _brandYellow,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 14),
        ],
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _secondaryBrown, fontSize: 14),
        ),
        ?action,
      ],
    ),
  );
}
