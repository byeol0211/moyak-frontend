import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moyak/widgets/pill_photo_sheet.dart';
import 'package:moyak/screens/chatbot_screen.dart';

void main() {
  test('uploads ordered front and back with repeated files field', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/pills/identify');
      expect(request.url.queryParameters, {'otc_only': 'false', 'limit': '3'});
      expect('name="files"'.allMatches(request.body).length, 2);
      expect(
        request.body.indexOf('pill-0.png'),
        lessThan(request.body.indexOf('pill-1.jpeg')),
      );
      return http.Response(
        jsonEncode({
          'message': 'candidates',
          'candidates': [],
          'note': 'back needed',
        }),
        200,
      );
    });
    final result = await identifyPillPhotos(client, [
      PillPhoto(Uint8List.fromList([1]), 'png'),
      PillPhoto(Uint8List.fromList([2]), 'jpeg'),
    ], testMode: true);
    expect(result['note'], 'back needed');
  });
  test('preserves server failure and rejects unsupported images', () async {
    final client = MockClient(
      (_) async => http.Response('{"detail":"try later"}', 429),
    );
    await expectLater(
      identifyPillPhotos(client, [
        PillPhoto(Uint8List(1), 'png'),
      ], testMode: true),
      throwsA(predicate((e) => e.toString().contains('try later'))),
    );
    await expectLater(
      PillPhoto.read(XFile.fromData(Uint8List.fromList([1, 2, 3]))),
      throwsException,
    );
    await expectLater(
      PillPhoto.read(XFile.fromData(Uint8List(8 * 1024 * 1024 + 1))),
      throwsException,
    );
    await expectLater(
      identifyPillPhotos(client, [], testMode: true),
      throwsException,
    );
  });
  testWidgets('attachment sheet opens without sending or clearing text', (
    tester,
  ) async {
    final client = MockClient((_) async {
      fail('no request before send');
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ChatPage(client: client)),
      ),
    );
    await tester.enterText(find.byType(TextField), 'draft');
    await tester.tap(find.byKey(const Key('chat-attach')));
    await tester.pumpAndSettle();
    expect(find.text('앨범에서 선택'), findsOneWidget);
    expect(find.text('카메라'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '사진 전송'))
          .onPressed,
      isNull,
    );
    Navigator.of(tester.element(find.text('알약 사진으로 찾기'))).pop();
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'draft',
    );
  });
  testWidgets(
    'candidate remains a candidate and explanation requires selection',
    (tester) async {
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PillResultCard(
              data: {
                'message': 'candidate message',
                'note': 'check back',
                'confident': false,
                'candidates': [
                  {
                    'item_name': 'medicine A',
                    'score': 0.9,
                    'print_front': 'AA',
                  },
                ],
              },
              onExplain: (name) => selected = name,
            ),
          ),
        ),
      );
      expect(selected, isNull);
      expect(find.text('check back'), findsOneWidget);
      expect(find.textContaining('90%'), findsNothing);
      await tester.tap(find.text('이 약에 대해 설명해 주세요'));
      expect(selected, 'medicine A');
    },
  );
}
