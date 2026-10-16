import 'package:flutter/material.dart';

enum PreviewListState { populated, empty, error }

class PreviewListControls extends StatelessWidget {
  const PreviewListControls({
    required this.value,
    required this.onChanged,
    super.key,
  });
  final PreviewListState value;
  final ValueChanged<PreviewListState> onChanged;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        const Expanded(child: Text('목록 미리보기')),
        DropdownButton<PreviewListState>(
          value: value,
          items: const [
            DropdownMenuItem(
              value: PreviewListState.populated,
              child: Text('예시 데이터'),
            ),
            DropdownMenuItem(
              value: PreviewListState.empty,
              child: Text('빈 목록'),
            ),
            DropdownMenuItem(
              value: PreviewListState.error,
              child: Text('조회 실패'),
            ),
          ],
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ],
    ),
  );
}
