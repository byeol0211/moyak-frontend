import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moyak/data/pill_api.dart';
import 'package:moyak/screens/chatbot_screen.dart';

const _recommendAnswer = '''열이 날 때 도움이 될 수 있는 약을 1가지 알려드릴게요.

💊 1. 보령펜시럽(덱시부프로펜)
· 추천 이유: 급성 상기도 감염으로 인한 발열 시 해열에 사용됩니다.
· 성분: 덱시부프로펜은 열을 내리는 데 도움을 줍니다.
· 주의: 임부는 복용을 피해야 합니다. (식약처 DUR)

복용법이나 더 자세한 주의사항이 궁금한 약을 말씀해 주시면 자세히 알려드릴게요.
정확한 진단과 복용은 약사와 상담하시기 바랍니다.
[참고: 보령펜시럽(덱시부프로펜)]''';

Widget _app(http.Client client, {PillPhotoPicker? pickPhotos}) => MaterialApp(
  home: Scaffold(
    body: ChatPage(client: client, pickPhotos: pickPhotos),
  ),
);

void main() {
  testWidgets('symptom answer is drawn as recommendation cards', (
    tester,
  ) async {
    final client = MockClient(
      (_) async => http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'answer': _recommendAnswer,
            'sources': ['보령펜시럽(덱시부프로펜)'],
            'evidence': [],
            'recommendations': [
              {
                'rank': 1,
                'item_name': '보령펜시럽(덱시부프로펜)',
                'reason': '급성 상기도 감염으로 인한 발열 시 해열에 사용됩니다.',
                'ingredient': '덱시부프로펜은 열을 내리는 데 도움을 줍니다.',
                'caution': '임부는 복용을 피해야 합니다. (식약처 DUR)',
              },
            ],
          }),
        ),
        200,
      ),
    );
    await tester.pumpWidget(_app(client));
    await tester.enterText(find.byType(TextField), '열이 나요');
    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('recommendation-1')), findsOneWidget);
    expect(find.text('보령펜시럽(덱시부프로펜)'), findsOneWidget);
    expect(find.text('✅ 추천 이유'), findsOneWidget);
    expect(find.text('🧪 성분'), findsOneWidget);
    expect(find.text('⚠️ 주의'), findsOneWidget);
    expect(find.text('임부는 복용을 피해야 합니다. (식약처 DUR)'), findsOneWidget);
    expect(
      find.text('복용법이나 더 자세한 주의사항이 궁금한 약을 말씀해 주시면 자세히 알려드릴게요.'),
      findsOneWidget,
    );
    // 안전 문구는 아래 노란 박스로 한 번만, 참고 줄은 "참고 약품:"으로만 보인다.
    expect(find.textContaining('[참고'), findsNothing);
    expect(find.text('정확한 진단과 복용은 약사와 상담하세요.'), findsOneWidget);
    expect(find.text('참고 약품: 보령펜시럽(덱시부프로펜)'), findsOneWidget);
  });

  testWidgets('pill photo shows candidates and asks chatbot about chosen one', (
    tester,
  ) async {
    final chatQuestions = <String>[];
    late http.BaseRequest pillRequest;
    final client = MockClient.streaming((request, body) async {
      if (request.url.path == '/pills/identify') {
        pillRequest = request;
        await body.drain<void>();
        return http.StreamedResponse(
          Stream.value(
            utf8.encode(
              jsonEncode({
                'detected': {'shape': '원형', 'color': '하양', 'confidence': 0.8},
                'candidates': [
                  {
                    'item_seq': '111',
                    'item_name': '타이레놀정500밀리그람',
                    'entp_name': '한국존슨앤드존슨',
                    'drug_shape': '장방형',
                    'color_class1': '하양',
                    'print_front': 'TYLENOL',
                    'score': 0.9,
                    'matched': ['모양'],
                  },
                  {
                    'item_seq': '222',
                    'item_name': '게보린정',
                    'score': 0.5,
                    'matched': [],
                  },
                ],
                'confident': false,
                'message': '사진과 비슷한 약을 찾았어요.',
              }),
            ),
          ),
          200,
        );
      }
      final data = jsonDecode(utf8.decode(await body.toBytes())) as Map;
      chatQuestions.add(data['question'] as String);
      return http.StreamedResponse(
        Stream.value(
          utf8.encode(
            jsonEncode({'answer': '진통제입니다.', 'sources': [], 'evidence': []}),
          ),
        ),
        200,
      );
    });

    await tester.pumpWidget(
      _app(
        client,
        pickPhotos: (_) async => const [
          PillPhoto(bytes: [1, 2, 3], name: 'front.jpg'),
        ],
      ),
    );
    await tester.tap(find.byKey(const Key('chat-pill-photo')));
    await tester.pumpAndSettle();

    expect(pillRequest.url.queryParameters['otc_only'], 'false');
    expect(find.byKey(const Key('pill-result')), findsOneWidget);
    expect(find.text('사진과 비슷한 약을 찾았어요.'), findsOneWidget);
    // 확실하지 않으면 후보를 여러 개 보여준다.
    expect(find.byKey(const Key('pill-candidate-111')), findsOneWidget);
    expect(find.byKey(const Key('pill-candidate-222')), findsOneWidget);

    await tester.tap(find.byKey(const Key('pill-candidate-111')));
    await tester.pumpAndSettle();
    expect(chatQuestions, ['타이레놀정500밀리그람은(는) 어떤 약인가요?']);
    expect(find.text('진통제입니다.'), findsOneWidget);
  });

  testWidgets('pill photo failure shows server message', (tester) async {
    final client = MockClient(
      (_) async =>
          http.Response.bytes(utf8.encode('{"detail":"사진이 너무 큽니다"}'), 413),
    );
    await tester.pumpWidget(
      _app(
        client,
        pickPhotos: (_) async => const [
          PillPhoto(bytes: [1], name: 'a.jpg'),
        ],
      ),
    );
    await tester.tap(find.byKey(const Key('chat-pill-photo')));
    await tester.pumpAndSettle();
    expect(find.text('사진이 너무 큽니다'), findsOneWidget);
    expect(find.byKey(const Key('pill-result')), findsNothing);
  });
}
