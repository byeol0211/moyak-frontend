import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moyak/data/auth_api.dart';
import 'package:moyak/data/auth_session.dart';
import 'package:moyak/data/api_client.dart';
import 'package:moyak/data/app_session.dart';
import 'package:moyak/config/app_config.dart';
import 'package:moyak/screens/login_page.dart';
import 'package:moyak/screens/mypage.dart';
import 'package:moyak/screens/screen_flows.dart';
import 'package:moyak/calls/consultation_chat.dart';

http.Response json(Object value, [int status = 200]) => http.Response(
  jsonEncode(value),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
Map<String, Object> session() => {
  'access_token': 'test-token',
  'token_type': 'bearer',
  'expires_in': 3600,
  'user': {
    'id': 'server-user',
    'username': 'tester',
    'name': '홍길동',
    'role': 'user',
  },
};
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthSession.clear();
    AppConfig.preview.value = false;
    AppSession.instance.userId = null;
    AppSession.instance.userName = null;
    AppSession.instance.username = null;
    AppSession.instance.userName = null;
    AppSession.instance.username = null;
  });
  tearDown(AuthSession.clear);
  test('signup rejects an empty name before making a request', () async {
    final auth = AuthApi(
      client: MockClient((_) async {
        fail('An empty name must not be sent to the API.');
      }),
    );

    await expectLater(
      auth.signup('tester', 'Password1!', name: '  '),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          '이름을 입력해주세요.',
        ),
      ),
    );
  });
  test(
    'duplicate signup and malformed response do not replace session',
    () async {
      AppSession.instance.userId = 'existing-user';
      AuthSession.set('existing-token', 3600);
      final duplicate = AuthApi(
        client: MockClient((request) async {
          expect(request.headers['authorization'], isNull);
          return json({'detail': '이미 사용 중인 아이디입니다.'}, 409);
        }),
      );
      await expectLater(
        duplicate.signup('tester', 'Password1!', name: '홍길동'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            '이미 사용 중인 아이디입니다.',
          ),
        ),
      );
      final malformed = AuthApi(
        client: MockClient(
          (_) async => json({...session(), 'access_token': ''}),
        ),
      );
      await expectLater(
        malformed.login('tester', 'Password1!'),
        throwsA(isA<ApiException>()),
      );
      expect(AppSession.instance.userId, 'existing-user');
      expect(AuthSession.headers()['Authorization'], 'Bearer existing-token');
    },
  );
  test(
    'login sends credentials, propagates token and logout removes it',
    () async {
      final client = MockClient((request) async {
        if (request.url.path == '/auth/login') {
          expect(jsonDecode(request.body), {
            'username': 'tester',
            'password': 'Password1!',
          });
          expect(request.headers['authorization'], isNull);
          return json(session());
        }
        expect(request.headers['authorization'], 'Bearer test-token');
        return json({});
      });
      await AuthApi(client: client).login(' tester ', 'Password1!');
      expect(AppSession.instance.userId, 'server-user');
      expect(AppSession.instance.userName, '홍길동');
      expect(AppSession.instance.username, 'tester');
      expect(AppSession.instance.displayName, '홍길동');
      expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
      await ApiClient(client: client).get('/consultations');
      await AppSession.instance.logout();
      expect(AuthSession.headers(), isEmpty);
      expect(AppSession.instance.userId, isNull);
    },
  );
  test(
    'failed login does not create a session; expired token allows login',
    () async {
      final auth = AuthApi(
        client: MockClient((_) async => json({'detail': '로그인 실패'}, 401)),
      );
      await expectLater(
        auth.login('tester', 'wrong'),
        throwsA(isA<ApiException>()),
      );
      expect(AppSession.instance.userId, isNull);
      AuthSession.set('expired', -1);
      expect(AuthSession.headers, throwsStateError);
      await AuthApi(client: MockClient((_) async => json(session())))
          .login('tester', 'Password1!');
      expect(AuthSession.headers()['Authorization'], 'Bearer test-token');
    },
  );
  test('consultation chat includes bearer token in reads and writes', () async {
    AuthSession.set('test-token', 3600);
    final chat = ApiConsultationChat(
      consultationId: 'c',
      userId: 'server-user',
      baseUrl: Uri.parse('https://example.test'),
      client: MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer test-token');
        if (request.method == 'POST') {
          return json({
            'id': 'm',
            'content': 'hello',
            'sender_role': 'user',
            'sender_id': 'server-user',
          });
        }
        return json(request.url.path.endsWith('/messages') ? [] : {});
      }),
    );
    await chat.poll();
    expect((await chat.send('hello')).local, isTrue);
  });
  testWidgets('login enters app only after successful API response', (
    tester,
  ) async {
    var entered = false;
    var fail = true;
    final auth = AuthApi(
      client: MockClient(
        (_) async => fail ? json({'detail': '로그인 실패'}, 401) : json(session()),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          auth: auth,
          onLogin: () => entered = true,
          onSignup: () {},
        ),
      ),
    );
    await tester.enterText(find.byType(TextField).at(0), 'tester');
    await tester.enterText(find.byType(TextField).at(1), 'Password1!');
    await tester.tap(find.text('로그인').last);
    await tester.pumpAndSettle();
    expect(entered, isFalse);
    expect(find.text('로그인 실패'), findsOneWidget);
    fail = false;
    await tester.tap(find.text('로그인').last);
    await tester.pumpAndSettle();
    expect(entered, isTrue);
    expect(AppSession.instance.userId, 'server-user');
    expect(AppSession.instance.displayName, '홍길동');
  });
  testWidgets('mypage displays the name returned by login', (tester) async {
    await AuthApi(client: MockClient((_) async => json(session())))
        .login('tester', 'Password1!');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Mypage(
            onOpenConsultHistory: () {},
            onOpenPermit: () {},
            onOpenInventory: () {},
          ),
        ),
      ),
    );

    expect(find.text('홍길동'), findsOneWidget);
  });
  testWidgets('signup saves name then mypage shows it', (tester) async {
    var entered = false;
    final auth = AuthApi(
      client: MockClient((request) async {
        if (request.url.path.endsWith('username-available')) {
          return json({'available': true});
        }
        expect(request.url.path, '/auth/signup');
        expect(jsonDecode(request.body), {
          'username': 'tester',
          'password': 'Password1!',
          'name': '홍길동',
        });
        return json(session(), 201);
      }),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SignupFlow(auth: auth, onComplete: () => entered = true),
      ),
    );
    await tester.enterText(find.byKey(const Key('signup-name')), '홍길동');
    await tester.enterText(find.byKey(const Key('signup-username')), 'tester');
    await tester.ensureVisible(find.text('중복확인'));
    await tester.tap(find.text('중복확인'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('signup-password')),
      'Password1!',
    );
    await tester.enterText(
      find.byKey(const Key('signup-confirm')),
      'Password1!',
    );
    await tester.ensureVisible(find.widgetWithText(FilledButton, '회원가입'));
    await tester.tap(find.widgetWithText(FilledButton, '회원가입'));
    await tester.pumpAndSettle();
    expect(entered, isTrue);
    expect(AppSession.instance.displayName, '홍길동');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Mypage(
            onOpenConsultHistory: () {},
            onOpenPermit: () {},
            onOpenInventory: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('홍길동'), findsOneWidget);
    await AppSession.instance.logout();
    expect(AppSession.instance.userName, isNull);
    expect(AppSession.instance.username, isNull);
  });

  testWidgets('blank name cannot submit signup', (tester) async {
    var calls = 0;
    final auth = AuthApi(
      client: MockClient((request) async {
        calls++;
        return json(session(), 201);
      }),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SignupFlow(auth: auth, onComplete: () {}),
      ),
    );
    await tester.ensureVisible(find.widgetWithText(FilledButton, '회원가입'));
    await tester.tap(find.widgetWithText(FilledButton, '회원가입'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('signup-name')));
    expect(find.text('이름을 입력해주세요.'), findsOneWidget);
    expect(calls, 0);
  });
}
