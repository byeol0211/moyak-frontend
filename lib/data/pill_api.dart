/// 알약 사진으로 약 후보를 찾는 `POST /pills/identify` 연동.
library;

import 'package:http/http.dart' as http;

import 'api_client.dart';

/// 사진 한 장. [name]은 서버가 확장자로 형식을 짐작할 때 쓴다.
class PillPhoto {
  const PillPhoto({required this.bytes, required this.name});

  final List<int> bytes;
  final String name;
}

class PillCandidate {
  const PillCandidate({
    required this.itemSeq,
    required this.itemName,
    this.company,
    this.imageUrl,
    this.shape,
    this.color,
    this.printFront,
    this.printBack,
    this.otcLabel,
    this.matched = const [],
  });

  factory PillCandidate.fromJson(Map json) => PillCandidate(
    itemSeq: '${json['item_seq'] ?? ''}',
    itemName: '${json['item_name'] ?? ''}',
    company: json['entp_name'] as String?,
    imageUrl: json['item_image'] as String?,
    shape: json['drug_shape'] as String?,
    color: json['color_class1'] as String?,
    printFront: json['print_front'] as String?,
    printBack: json['print_back'] as String?,
    otcLabel: json['etc_otc_name'] as String?,
    matched: json['matched'] is List
        ? [for (final m in json['matched'] as List) '$m']
        : const [],
  );

  final String itemSeq;
  final String itemName;
  final String? company;
  final String? imageUrl;
  final String? shape;
  final String? color;
  final String? printFront;
  final String? printBack;
  final String? otcLabel;
  final List<String> matched;
}

class PillResult {
  const PillResult({
    required this.candidates,
    required this.confident,
    required this.message,
    this.note,
  });

  factory PillResult.fromJson(Map json) => PillResult(
    candidates: json['candidates'] is List
        ? [
            for (final c in json['candidates'] as List)
              if (c is Map) PillCandidate.fromJson(c),
          ]
        : const [],
    confident: json['confident'] == true,
    message: '${json['message'] ?? ''}',
    note: json['note'] as String?,
  );

  final List<PillCandidate> candidates;

  /// 거짓이면 1위를 정답처럼 보여주지 말고 사용자가 고르게 한다.
  final bool confident;
  final String message;
  final String? note;
}

class PillApi {
  PillApi({http.Client? client}) : _api = ApiClient(client: client);

  final ApiClient _api;

  /// 같은 알약의 앞면(+뒷면) 사진. 서버는 2장까지만 본다.
  /// 챗봇에서는 전문의약품도 찾도록 `otc_only=false`로 부른다(백엔드 권장값).
  Future<PillResult> identify(List<PillPhoto> photos) async {
    if (photos.isEmpty) throw ApiException('알약 사진을 한 장 이상 골라주세요.');
    final data = await _api.postFiles(
      '/pills/identify',
      query: {'otc_only': 'false', 'limit': '5'},
      files: [
        for (final p in photos.take(2))
          http.MultipartFile.fromBytes('files', p.bytes, filename: p.name),
      ],
      // 서버가 사진 분석에 5~15초, 무료 서버가 깨어나는 데 최대 1분 걸린다.
      timeout: const Duration(seconds: 90),
    );
    if (data is! Map || data['candidates'] is! List) {
      throw ApiException('알약 인식 응답을 읽지 못했어요.');
    }
    return PillResult.fromJson(data);
  }

  void close() => _api.close();
}
