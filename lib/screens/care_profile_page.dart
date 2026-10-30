import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../data/api_client.dart';
import '../data/auth_session.dart';
import '../widgets/consult_header.dart';

/// Existing structured condition/medication tables; purchase history is read-only.
class CareProfilePage extends StatefulWidget {
  const CareProfilePage({super.key, this.api});
  final ApiClient? api;
  @override
  State<CareProfilePage> createState() => _CareProfilePageState();
}

class _CareProfilePageState extends State<CareProfilePage> {
  late final ApiClient _api = widget.api ?? ApiClient();
  final _form = GlobalKey<FormState>();
  final _note = TextEditingController();
  final _drug = TextEditingController();
  final _conditions = <Map<String, dynamic>>[];
  final _medications = <Map<String, dynamic>>[];
  final _readOnly = <Map<String, dynamic>>[];
  static const _labels = {
    'allergy': '알러지',
    'disease': '질환',
    'pregnancy': '임신',
    'breastfeeding': '수유',
    'other': '기타',
  };
  String? _revision;
  String? _error;
  String? _notice;
  bool _busy = true;
  int _rowKey = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _apply(Map<String, dynamic> data) {
    _revision = data['revision'] as String;
    _drug.clear();
    _note.text = data['care_note'] as String? ?? '';
    _conditions.clear();
    _medications.clear();
    _readOnly.clear();
    for (final entry in data['conditions'] as List) {
      _conditions.add({
        ...Map<String, dynamic>.from(entry as Map),
        '_key': _rowKey++,
      });
    }
    for (final entry in data['medications'] as List) {
      final row = {
        ...Map<String, dynamic>.from(entry as Map),
        '_key': _rowKey++,
      };
      (row['source'] == 'manual' ? _medications : _readOnly).add(row);
    }
  }

  String _apiError(ApiException error) {
    if (error.statusCode == 404 && error.message == 'Not Found') {
      return '현재 연결된 서버에 상담 참고사항 기능이 아직 반영되지 않았어요. 서버 업데이트 후 다시 시도해주세요.';
    }
    return error.message;
  }

  Future<void> _load() async {
    if (AppConfig.preview.value || !AuthSession.isAuthenticated) {
      setState(() {
        _busy = false;
        _revision = null;
        _error = null;
        _notice = '상담 참고사항은 로그인 후 이용할 수 있어요. 게스트·미리보기에서는 개인 정보를 저장하지 않습니다. 마이페이지에서 로그아웃한 뒤 로그인해주세요.';
      });
      return;
    }
    _notice = null;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await _api.get('/auth/me/care-profile');
      if (mounted) {
        setState(() => _apply(Map<String, dynamic>.from(data as Map)));
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ApiException
              ? _apiError(error)
              : error is StateError
              ? error.message.toString()
              : '참고사항을 불러오지 못했어요. 연결을 확인하고 다시 시도해주세요.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_medications.any(
      (r) => (r['drug_name'] as String? ?? '').trim().isEmpty,
    )) {
      setState(() => _error = '복용 중인 약 이름을 입력해주세요.');
      return;
    }
    if (_drug.text.trim().isNotEmpty && !_addDrug()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await _api.patch(
        '/auth/me/care-profile',
        body: {
          'revision': _revision,
          'care_note': _note.text,
          'conditions': [
            for (final r in _conditions)
              {
                if (r['id'] != null) 'id': r['id'],
                'condition_type': r['condition_type'],
                'label': (r['label'] as String? ?? '').trim(),
                'note': r['note'],
              },
          ],
          'medications': [
            for (final r in _medications)
              {
                if (r['id'] != null) 'id': r['id'],
                'drug_name': (r['drug_name'] as String? ?? '').trim(),
                'dosage_note': r['dosage_note'],
              },
          ],
        },
      );
      if (!mounted) return;
      setState(() => _apply(Map<String, dynamic>.from(data as Map)));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('상담 참고사항을 저장했어요. 약사가 상담 화면에서 확인할 수 있어요.')),
      );
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ApiException
              ? _apiError(error)
              : error is StateError
              ? error.message.toString()
              : '참고사항을 저장하지 못했어요. 입력 내용은 유지되니 연결을 확인하고 다시 시도해주세요.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reload() async {
    if (_revision != null) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: const Text('저장하지 않은 입력을 버리고 다시 불러올까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('불러오기'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    await _load();
  }

  Widget _row(Map<String, dynamic> row, bool medication) {
    final field = medication ? 'drug_name' : 'label';
    final note = medication ? 'dosage_note' : 'note';
    return Card(
      key: ValueKey(row['_key']),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            if (!medication)
              DropdownButtonFormField<String>(
                initialValue: row['condition_type'] as String,
                decoration: const InputDecoration(labelText: '항목 구분'),
                items: [
                  for (final e in _labels.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                onChanged: (value) => row['condition_type'] = value,
              ),
            TextFormField(
              initialValue: row[field] as String? ?? '',
              maxLength: 200,
              decoration: InputDecoration(
                labelText: medication ? '복용 중인 약 이름' : '참고사항',
                hintText: medication ? '약 이름' : '예: 페니실린 알러지 / 고혈압 / 임신 12주',
              ),
              onChanged: (value) => row[field] = value,
              validator: (value) =>
                  value == null || value.trim().isEmpty ? '내용을 입력해주세요.' : null,
            ),
            TextFormField(
              initialValue: row[note] as String? ?? '',
              maxLength: 1000,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: medication ? '복용 방법·메모 (선택)' : '추가 설명 (선택)',
              ),
              onChanged: (value) => row[note] = value,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => setState(
                  () => (medication ? _medications : _conditions).remove(row),
                ),
                icon: const Icon(Icons.delete_outline),
                label: const Text('항목 삭제'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _cream = Color(0xFFFFF7D5);
  static const _yellow = Color(0xFFFFD54F);
  static const _ink = Color(0xFF21443E);
  static const _muted = Color(0xFF7A8C87);
  static const _line = Color(0xFFBDD4CE);
  static const _allergies = [
    '알러지 없음',
    '페니실린계 항생제',
    '아스피린 · 소염진통제',
    '설파제',
    '조영제',
    '식품(계란 · 우유 등)',
  ];
  static const _diseases = [
    '해당 없음',
    '고혈압',
    '당뇨',
    '천식',
    '위 · 십이지장 질환',
    '간 질환',
    '신장 질환',
    '심장 질환',
    '녹내장',
  ];

  InputDecoration _input(String hint) => InputDecoration(
    hintText: hint,
    counterText: '',
    filled: true,
    fillColor: Colors.white,
    hintStyle: const TextStyle(color: _muted, fontSize: 14),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _line, width: 1.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _line, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: consultGreen, width: 1.5),
    ),
  );

  bool _selected(String type, String label) => _conditions.any(
    (r) => r['condition_type'] == type && r['label'] == label,
  );
  void _toggle(String type, String label) => setState(() {
    if (_selected(type, label)) {
      _conditions.removeWhere(
        (r) => r['condition_type'] == type && r['label'] == label,
      );
      return;
    }
    final none = type == 'allergy' ? '알러지 없음' : '해당 없음';
    if (label == none) {
      _conditions.removeWhere((r) => r['condition_type'] == type);
    } else {
      _conditions.removeWhere(
        (r) => r['condition_type'] == type && r['label'] == none,
      );
    }
    if (_conditions.length < 30) {
      _conditions.add({
        '_key': _rowKey++,
        'condition_type': type,
        'label': label,
      });
    }
  });

  bool _addDrug() {
    final name = _drug.text.trim();
    if (name.isEmpty) return true;
    if (_medications.length >= 30) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('복용약은 최대 30개까지 입력할 수 있어요.')));
      return false;
    }
    setState(() {
      _medications.add({'_key': _rowKey++, 'drug_name': name});
      _drug.clear();
    });
    return true;
  }

  Widget _card(
    int number,
    String title,
    List<Widget> children, {
    String? hint,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFF0E2AE)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: _yellow,
              foregroundColor: _ink,
              child: Text(
                '$number',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (hint != null)
              Text(hint, style: const TextStyle(color: _muted, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    ),
  );

  Widget _chip(
    String text,
    bool selected,
    VoidCallback onTap, {
    bool square = false,
  }) => FilterChip(
    label: Text(text),
    selected: selected,
    onSelected: (_) => onTap(),
    showCheckmark: !square,
    checkmarkColor: _yellow,
    selectedColor: consultGreen,
    backgroundColor: Colors.white,
    labelStyle: TextStyle(
      color: selected ? Colors.white : _ink,
      fontSize: 14,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(square ? 14 : 28),
    ),
    side: BorderSide(color: selected ? consultGreen : _line, width: 1.5),
  );

  Widget _conditionCard(
    int number,
    String title,
    String type,
    List<String> options,
  ) {
    final custom = _conditions
        .where(
          (r) => r['condition_type'] == type && !options.contains(r['label']),
        )
        .toList();
    return _card(number, title, [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final label in options)
            _chip(label, _selected(type, label), () => _toggle(type, label)),
          _chip(
            '기타',
            custom.isNotEmpty,
            () => setState(() {
              if (custom.isNotEmpty) {
                _conditions.removeWhere(custom.contains);
              } else if (_conditions.length < 30) {
                _conditions.removeWhere(
                  (r) =>
                      r['condition_type'] == type &&
                      ['알러지 없음', '해당 없음'].contains(r['label']),
                );
                _conditions.add({
                  '_key': _rowKey++,
                  'condition_type': type,
                  'label': '',
                });
              }
            }),
          ),
        ],
      ),
      for (final row in custom) ...[
        const SizedBox(height: 16),
        Text(
          type == 'allergy' ? '기타 알러지를 직접 적어주세요' : '기타 질환을 직접 적어주세요',
          style: const TextStyle(
            color: consultGreen,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: ValueKey(row['_key']),
          initialValue: row['label'] as String? ?? '',
          maxLength: 200,
          decoration: _input(
            type == 'allergy' ? '예: 땅콩, 특정 약 이름' : '질환 이름을 입력해주세요',
          ),
          onChanged: (v) => row['label'] = v,
          validator: (v) =>
              v == null || v.trim().isEmpty ? '내용을 입력해주세요.' : null,
        ),
      ],
    ], hint: '복수 선택');
  }

  bool get _pregnancyNone =>
      _selected('pregnancy', '해당 없음') && _selected('breastfeeding', '해당 없음');
  void _pregnancy(String label) => setState(() {
    final none = label == '해당 없음';
    final type = label == '임신 중' ? 'pregnancy' : 'breastfeeding';
    final selected = none ? _pregnancyNone : _selected(type, label);
    _conditions.removeWhere(
      (r) =>
          ['pregnancy', 'breastfeeding'].contains(r['condition_type']) &&
          (none ||
              r['label'] == '해당 없음' ||
              (r['condition_type'] == type && r['label'] == label)),
    );
    if (!selected) {
      for (final t in none ? ['pregnancy', 'breastfeeding'] : [type]) {
        if (_conditions.length < 30) {
          _conditions.add({
            '_key': _rowKey++,
            'condition_type': t,
            'label': label,
          });
        }
      }
    }
  });

  Widget _medication(Map<String, dynamic> row) => Container(
    key: ValueKey(row['_key']),
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFE8F4EF),
      borderRadius: BorderRadius.circular(14),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.only(left: 16, right: 4),
      leading: const Icon(
        Icons.medication_outlined,
        size: 20,
        color: consultGreen,
      ),
      title: Text(
        row['drug_name'] as String,
        style: const TextStyle(
          color: _ink,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: (row['dosage_note'] as String? ?? '').isEmpty
          ? null
          : Text(row['dosage_note'] as String),
      onTap: () async {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('복용약 수정'),
            content: SingleChildScrollView(child: _row(row, true)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('닫기'),
              ),
            ],
          ),
        );
        if (mounted) setState(() {});
      },
      trailing: IconButton(
        tooltip: '복용약 삭제',
        icon: const Icon(Icons.close, color: consultGreen),
        onPressed: () => setState(() => _medications.remove(row)),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      colorScheme: Theme.of(context).colorScheme
          .copyWith(primary: consultGreen, onPrimary: Colors.white),
    ),
    child: Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        foregroundColor: _ink,
        title: const Text('상담 참고사항'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _reload,
            tooltip: '다시 불러오기',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_busy) const LinearProgressIndicator(),
          if (_notice != null)
            Padding(padding: const EdgeInsets.all(24), child: Text(_notice!)),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          if (_error != null && !_busy)
            TextButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 불러오기'),
            ),
          if (_revision != null)
            Expanded(
              child: AbsorbPointer(
                absorbing: _busy,
                child: Form(
                  key: _form,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBE985),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: consultGreen,
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '한 번 적어두면 상담할 때마다 다시 설명하지 않아도 돼요.',
                                style: TextStyle(
                                  color: _ink,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _conditionCard(1, '알러지', 'allergy', _allergies),
                      _conditionCard(2, '앓고 있는 질환', 'disease', _diseases),
                      _card(3, '임신 · 수유 여부', [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final label in ['해당 없음', '임신 중', '수유 중'])
                              _chip(
                                label,
                                label == '해당 없음'
                                    ? _pregnancyNone
                                    : _selected(
                                        label == '임신 중'
                                            ? 'pregnancy'
                                            : 'breastfeeding',
                                        label,
                                      ),
                                () => _pregnancy(label),
                                square: true,
                              ),
                          ],
                        ),
                        for (final row in _conditions.where(
                          (r) =>
                              [
                                'pregnancy',
                                'breastfeeding',
                              ].contains(r['condition_type']) &&
                              !['해당 없음', '임신 중', '수유 중'].contains(r['label']),
                        ))
                          _row(row, false),
                        const SizedBox(height: 14),
                        const Text(
                          '임신 중이거나 수유 중이면 복용할 수 없는 약이 있어요.',
                          style: TextStyle(color: _muted, fontSize: 12),
                        ),
                      ]),
                      _card(4, '현재 복용 중인 약', [
                        for (final row in _medications) _medication(row),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _drug,
                                maxLength: 200,
                                decoration: _input('약 이름을 입력하세요'),
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _addDrug(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 50,
                              height: 54,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: _yellow,
                                  foregroundColor: _ink,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: _medications.length >= 30
                                    ? null
                                    : _addDrug,
                                child: const Icon(Icons.add, size: 28),
                              ),
                            ),
                          ],
                        ),
                        for (final row in _readOnly)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.lock_outline,
                              size: 18,
                              color: _muted,
                            ),
                            title: Text(row['drug_name'] as String),
                            subtitle: Text(
                              '구매·처방 기록 (조회 전용)\n${row['dosage_note'] ?? ''}',
                            ),
                          ),
                      ]),
                      _card(5, '기타 참고사항', [
                        TextFormField(
                          controller: _note,
                          maxLength: 500,
                          maxLines: 5,
                          decoration: _input(
                            '증상, 약을 먹고 불편했던 경험, 약사님께 묻고 싶은 점을 자유롭게 적어주세요',
                          ),
                        ),
                        for (final row in _conditions.where(
                          (r) => ![
                            'allergy',
                            'disease',
                            'pregnancy',
                            'breastfeeding',
                          ].contains(r['condition_type']),
                        ))
                          _row(row, false),
                      ], hint: '선택'),
                      const Text(
                        '미입력 항목은 “해당 없음”을 의미하지 않습니다.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _revision == null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: _busy ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: consultGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          _busy ? '저장 중...' : '저장하기',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '약사님과 상담할 때 반영됩니다.',
                      style: TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
    ),
  );

  @override
  void dispose() {
    _note.dispose();
    _drug.dispose();
    if (widget.api == null) _api.close();
    super.dispose();
  }
}
