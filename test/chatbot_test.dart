import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moyak/screens/chatbot_screen.dart';

void main() {
  testWidgets('sends question and carries successful conversation history', (
    tester,
  ) async {
    final requests = <Map<String, dynamic>>[];
    final client = MockClient((r) async {
      expect(r.url.path, '/chat');
      requests.add(jsonDecode(r.body));
      return http.Response(
        jsonEncode({
          'answer': 'answer ${requests.length}',
          'sources': [],
          'evidence': [],
        }),
        200,
      );
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ChatPage(client: client)),
      ),
    );
    expect(find.text('안녕하세요, 전 모약이에요!'), findsOneWidget);
    expect(find.text('약에 대해 궁금하신 점이 있나요?'), findsOneWidget);
    expect(requests, isEmpty);
    expect(find.text('도움돼요'), findsNothing);
    await tester.enterText(find.byType(TextField), 'first');
    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pumpAndSettle();
    expect(find.text('answer 1'), findsOneWidget);
    expect(find.text('도움돼요'), findsOneWidget);
    expect(requests.first['history'], isEmpty);
    await tester.enterText(find.byType(TextField), 'second');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();
    expect(requests.last['history'], [
      {'role': 'user', 'content': 'first'},
      {'role': 'assistant', 'content': 'answer 1'},
    ]);
    expect(find.text('answer 2'), findsOneWidget);
  });

  testWidgets('shows server failure and restores input for retry', (
    tester,
  ) async {
    final client = MockClient(
      (_) async => http.Response('{"detail":"AI unavailable"}', 503),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ChatPage(client: client)),
      ),
    );
    await tester.enterText(find.byType(TextField), 'question');
    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pumpAndSettle();
    expect(find.text('AI unavailable'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'question',
    );
    expect(
      tester.widget<IconButton>(find.byKey(const Key('chat-send'))).onPressed,
      isNotNull,
    );
  });
}
