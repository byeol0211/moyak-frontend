import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moyak/screens/chatbot_screen.dart';

const _recommendAnswer = '''열이 날 때 도움이 될 수 있는 약을 1가지 알려드릴게요.

💊 1. 보령펜시럽(덱시부프로펜)
· 추천 이유: 급성 상기도 감염으로 인한 발열 시 해열에 사용됩니다.
· 성분: 덱시부프로펜은 열을 내리는 데 도움을 줍니다.
· 주의: 임부는 복용을 피해야 합니다. (식약처 DUR)

복용법이나 더 자세한 주의사항이 궁금한 약을 말씀해 주시면 자세히 알려드릴게요.
정확한 진단과 복용은 약사와 상담하시기 바랍니다.
[참고: 보령펜시럽(덱시부프로펜)]''';

Widget _app(http.Client client) => MaterialApp(
  home: Scaffold(body: ChatPage(client: client)),
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
}
