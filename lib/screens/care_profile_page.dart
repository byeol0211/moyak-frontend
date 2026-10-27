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

  // 챗봇 화면과 같은 초록색으로 이 화면의 버튼들을 맞춘다.
  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      colorScheme: Theme.of(context).colorScheme
          .copyWith(primary: consultGreen, onPrimary: Colors.white),
    ),
    child: _buildPage(context),
  );

  Widget _buildPage(BuildContext context) => Scaffold(
    // 저장 버튼은 스크롤 목록 밖 하단에 고정해 기기 하단 바와 겹치지 않게 한다.
    bottomNavigationBar: _revision == null
        ? null
        : SafeArea(
            top: false,
            child: Padding(
              // 기기 하단 바 높이와 별개로 여유를 둬 버튼이 가려지지 않게 한다.
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
              child: SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _busy ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: consultGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('참고사항 저장'),
                ),
              ),
            ),
          ),
    appBar: AppBar(
      title: const Text('상담 참고사항'),
      actions: [
        IconButton(
          onPressed: _busy ? null : _reload,
          icon: const Icon(Icons.refresh),
          tooltip: '다시 불러오기',
        ),
      ],
    ),
    body: Column(
      children: [
        if (_busy) const LinearProgressIndicator(),
        if (_notice != null)
          Padding(padding: const EdgeInsets.all(24), child: Text(_notice!)),
        if (_error != null && !_busy)
          TextButton.icon(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
            label: const Text('다시 불러오기'),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_error!, style: const TextStyle(color: Colors.red)),
          ),
        if (_revision != null)
          Expanded(
            child: AbsorbPointer(
              absorbing: _busy,
              child: Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      '저장한 내용은 약사 상담 시 전달됩니다. 미등록 항목은 “해당 없음”을 의미하지 않습니다.',
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '알러지·질환·임신·수유',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    for (final row in _conditions) _row(row, false),
                    TextButton.icon(
                      onPressed: _conditions.length >= 30
                          ? null
                          : () => setState(
                              () => _conditions.add({
                                '_key': _rowKey++,
                                'condition_type': 'allergy',
                                'label': '',
                              }),
                            ),
                      icon: const Icon(Icons.add),
                      label: const Text('참고사항 추가'),
                    ),
                    const Text(
                      '현재 복용약',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    for (final row in _medications) _row(row, true),
                    TextButton.icon(
                      onPressed: _medications.length >= 30
                          ? null
                          : () => setState(
                              () => _medications.add({
                                '_key': _rowKey++,
                                'drug_name': '',
                              }),
                            ),
                      icon: const Icon(Icons.add),
                      label: const Text('복용약 추가'),
                    ),
                    for (final row in _readOnly)
                      ListTile(
                        title: Text(row['drug_name'] as String),
                        subtitle: Text(
                          '구매·처방 기록 (이 화면에서 수정하지 않음)\n${row['dosage_note'] ?? ''}',
                        ),
                      ),
                    TextFormField(
                      controller: _note,
                      maxLength: 500,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: '기타 메모'),
                    ),
                    const Text(
                      '직접 입력한 내용은 약사의 확인용 정보입니다. 약품·성분 코드로 자동 판정되는 정보는 아닙니다.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );

  @override
  void dispose() {
    _note.dispose();
    if (widget.api == null) _api.close();
    super.dispose();
  }
}
