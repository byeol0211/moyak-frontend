import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moyak/data/app_session.dart';
import 'package:moyak/data/auth_api.dart';
import 'package:moyak/data/auth_session.dart';
import 'package:moyak/screens/mypage.dart';

Widget _page(AuthApi auth) => MaterialApp(
  home: Scaffold(
    body: Mypage(
      onOpenConsultHistory: () {},
      onOpenPermit: () {},
      onOpenInventory: () {},
      auth: auth,
    ),
  ),
);

http.Response _json(Object body, [int status = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), status);

void main() {
  tearDown(() {
    AuthSession.clear();
    AppSession.instance
      ..userId = null
      ..userName = null
      ..username = null;
  });

  testWidgets('loads name from /auth/me and saves edited name', (tester) async {
    AuthSession.set('token', 3600);
    AppSession.instance
      ..userId = 'u1'
      ..userName = null
      ..username = 'moyak01';
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      expect(request.url.path, '/auth/me');
      expect(request.headers['Authorization'], 'Bearer token');
      if (request.method == 'PATCH') {
        final name = (jsonDecode(request.body) as Map)['name'];
        return _json({
          'id': 'u1',
          'username': 'moyak01',
          'name': name,
          'role': 'user',
        });
      }
      return _json({
        'id': 'u1',
        'username': 'moyak01',
        'name': '김모약',
        'role': 'user',
      });
    });

    await tester.pumpWidget(_page(AuthApi(client: client)));
    await tester.pumpAndSettle();
    expect(find.text('김모약'), findsOneWidget);

    await tester.tap(find.byKey(const Key('mypage-edit-name')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('mypage-name-field')), ' 이모약 ');
    await tester.tap(find.byKey(const Key('mypage-name-save')));
    await tester.pumpAndSettle();

    expect(requests.last.method, 'PATCH');
    expect(jsonDecode(requests.last.body), {'name': '이모약'});
    expect(find.text('이모약'), findsOneWidget);
    expect(AppSession.instance.userName, '이모약');
  });

  testWidgets('guest without token cannot edit name and makes no request', (
    tester,
  ) async {
    AppSession.instance.userId = 'guest-id';
    var called = false;
    final client = MockClient((_) async {
      called = true;
      return _json({});
    });
    await tester.pumpWidget(_page(AuthApi(client: client)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mypage-edit-name')), findsNothing);
    expect(called, isFalse);
  });
}
