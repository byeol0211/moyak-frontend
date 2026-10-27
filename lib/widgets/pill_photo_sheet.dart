import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../config/app_config.dart';
import 'consult_header.dart';

class PillPhoto {
  PillPhoto(this.bytes, this.type);
  final Uint8List bytes;
  final String type;
  static Future<PillPhoto> read(XFile file) async {
    if (await file.length() > 8 * 1024 * 1024) {
      throw Exception('사진 한 장은 8MB 이하여야 합니다. 작은 사진을 선택해주세요.');
    }
    final bytes = await file.readAsBytes();
    final png =
        bytes.length >= 8 &&
        bytes[0] == 137 &&
        bytes[1] == 80 &&
        bytes[2] == 78 &&
        bytes[3] == 71;
    final jpeg =
        bytes.length >= 3 &&
        bytes[0] == 255 &&
        bytes[1] == 216 &&
        bytes[2] == 255;
    if (!png && !jpeg) throw Exception('JPEG 또는 PNG 사진을 선택해주세요.');
    return PillPhoto(bytes, png ? 'png' : 'jpeg');
  }
}

Future<Map<String, dynamic>> identifyPillPhotos(
  http.Client client,
  List<PillPhoto> photos, {
  bool testMode = false,
}) async {
  if (photos.isEmpty || photos.length > 2) throw Exception('사진은 1~2장 선택해주세요.');
  final uri =
      (testMode && AppConfig.apiBaseUrl.isEmpty
              ? Uri(path: '/pills/identify')
              : AppConfig.endpoint('/pills/identify'))
          .replace(queryParameters: {'otc_only': 'false', 'limit': '3'});
  final request = http.MultipartRequest('POST', uri);
  for (var i = 0; i < photos.length; i++) {
    final photo = photos[i];
    request.files.add(
      http.MultipartFile.fromBytes(
        'files',
        photo.bytes,
        filename: 'pill-$i.${photo.type}',
        contentType: MediaType('image', photo.type),
      ),
    );
  }
  final response = await (() async => http.Response.fromStream(
    await client.send(request),
  ))().timeout(const Duration(seconds: 90));
  dynamic data;
  try {
    data = jsonDecode(utf8.decode(response.bodyBytes));
  } catch (_) {
    throw Exception('사진 분석 응답을 읽지 못했어요 (${response.statusCode}).');
  }
  if (response.statusCode != 200) {
    throw Exception(
      data is Map && data['detail'] is String
          ? data['detail']
          : '사진 분석에 실패했어요 (${response.statusCode}).',
    );
  }
  if (data is! Map<String, dynamic> ||
      data['message'] is! String ||
      data['candidates'] is! List) {
    throw Exception('사진 분석 응답 형식이 올바르지 않습니다.');
  }
  return data;
}

class PillPhotoSheet extends StatefulWidget {
  const PillPhotoSheet({
    required this.client,
    this.testMode = false,
    super.key,
  });
  final http.Client client;
  final bool testMode;
  @override
  State<PillPhotoSheet> createState() => _PillPhotoSheetState();
}

class _PillPhotoSheetState extends State<PillPhotoSheet> {
  final _photos = <PillPhoto>[];
  bool _busy = false;
  String? _error;
  Future<void> _pick(bool camera) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final picker = ImagePicker();
      final files = camera
          ? [
              await picker.pickImage(
                source: ImageSource.camera,
                maxWidth: 1600,
                maxHeight: 1600,
                imageQuality: 90,
              ),
            ].whereType<XFile>().toList()
          : await picker.pickMultiImage(
              maxWidth: 1600,
              maxHeight: 1600,
              imageQuality: 90,
            );
      if (files.length + _photos.length > 2) {
        throw Exception('같은 약의 앞면·뒷면 사진을 최대 2장 선택해주세요.');
      }
      final photos = <PillPhoto>[];
      for (final file in files) {
        photos.add(await PillPhoto.read(file));
      }
      if (mounted) setState(() => _photos.addAll(photos));
    } catch (e) {
      if (mounted) {
        setState(() => _error = '$e'.replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    if (_busy || _photos.isEmpty) return;
    if (AppConfig.preview.value && !widget.testMode) {
      setState(() => _error = '사진 분석은 실제 서버에 연결한 상태에서 사용할 수 있어요.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await identifyPillPhotos(
        widget.client,
        _photos,
        testMode: widget.testMode,
      );
      if (mounted) {
        Navigator.pop(context, {
          ...data,
          'photos': List<PillPhoto>.of(_photos),
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = '$e'.replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '알약 사진으로 찾기',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: consultBrown,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '한 알만 가까이 찍어 주세요. 같은 약의 앞면·뒷면 두 장이면 더 정확해요. JPEG/PNG, 한 장 8MB 이하',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _busy || _photos.length == 2
                      ? null
                      : () => _pick(true),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('카메라'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy || _photos.length == 2
                      ? null
                      : () => _pick(false),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('앨범에서 선택'),
                ),
              ],
            ),
            PillPhotoThumbnails(
              photos: _photos,
              onRemove: _busy
                  ? null
                  : (i) => setState(() => _photos.removeAt(i)),
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  '사진을 처리하고 있어요. 분석에는 약 5~15초가 걸리며 서버 상태에 따라 더 걸릴 수 있어요.',
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            FilledButton(
              onPressed: _busy || _photos.isEmpty ? null : _send,
              child: Text(_busy ? '처리 중…' : '사진 전송'),
            ),
          ],
        ),
      ),
    ),
  );
}

class PillPhotoThumbnails extends StatelessWidget {
  const PillPhotoThumbnails({required this.photos, this.onRemove, super.key});
  final List<PillPhoto> photos;
  final ValueChanged<int>? onRemove;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    children: [
      for (var i = 0; i < photos.length; i++)
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.memory(
              photos[i].bytes,
              width: 110,
              height: 110,
              fit: BoxFit.cover,
              errorBuilder: (_, error, stack) => const SizedBox(
                width: 110,
                height: 110,
                child: Icon(Icons.broken_image_outlined),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(i == 0 ? '앞면' : '뒷면'),
                if (onRemove != null)
                  IconButton(
                    tooltip: '사진 삭제',
                    onPressed: () => onRemove!(i),
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
          ],
        ),
    ],
  );
}

class PillResultCard extends StatelessWidget {
  const PillResultCard({required this.data, this.onExplain, super.key});
  final Map<String, dynamic> data;
  final ValueChanged<String>? onExplain;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(data['message'] as String),
          if (data['note'] is String && (data['note'] as String).isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                data['note'],
                style: const TextStyle(
                  color: consultBrown,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          for (final candidate
              in (data['candidates'] as List).whereType<Map>().take(3))
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: consultLine),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (candidate['item_image'] is String &&
                      Uri.tryParse(candidate['item_image'])?.scheme == 'https')
                    Image.network(
                      candidate['item_image'],
                      height: 90,
                      fit: BoxFit.contain,
                      errorBuilder: (_, error, stack) =>
                          const Icon(Icons.medication_outlined),
                    ),
                  Text(
                    '${candidate['item_name'] ?? '이름 없음'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    [
                      candidate['entp_name'],
                      candidate['etc_otc_name'],
                    ].whereType<String>().join(' · '),
                  ),
                  Text(
                    '각인: ${candidate['print_front'] ?? '-'} / ${candidate['print_back'] ?? '-'}',
                  ),
                  TextButton(
                    onPressed:
                        onExplain == null || candidate['item_name'] is! String
                        ? null
                        : () => onExplain!(candidate['item_name']),
                    child: const Text('이 약에 대해 설명해 주세요'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          const Text(
            '사진만으로는 틀릴 수 있어요. 포장이나 약사에게 꼭 확인하세요.',
            style: TextStyle(color: consultMutedBrown),
          ),
        ],
      ),
    ),
  );
}
