import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moyak/config/app_config.dart';
import 'package:moyak/data/app_session.dart';
import 'package:moyak/data/machine_qr.dart';
import 'package:moyak/data/models.dart';
import 'package:moyak/main.dart';
import 'package:moyak/screens/consult_history_screen.dart';
import 'package:moyak/screens/login_page.dart';
import 'package:moyak/screens/permission_screen.dart';
import 'package:moyak/screens/signup_step1_screen.dart';
import 'package:moyak/screens/signup_step2_screen.dart';
import 'package:moyak/screens/screen_flows.dart';
import 'package:moyak/screens/video_consultation_page.dart';
import 'package:moyak/utils/input_validation.dart';

Future<void> phone(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(402, 874),
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppConfig.preview.value = false;
    AppSession.instance.cancelConsultation();
    AppSession.instance.history.clear();
    AppSession.instance.permits.clear();
  });
  tearDown(() => AppConfig.preview.value = false);

  test('password requires a special character other than whitespace', () {
    expect(InputValidation.password('Password1 '), isFalse);
    expect(InputValidation.password('Password1!'), isTrue);
    expect(InputValidation.password('Pass 1!word'), isFalse);
    expect(InputValidation.username('abc'), isFalse);
    expect(InputValidation.username('moyak_12'), isTrue);
  });

  test('QR rejects foreign data and missing credentials', () {
    for (final raw in [
      'https://example.com',
      '[]',
      '{}',
      '{"machine_id":"M001","qr_token":" "}',
      '{"machine_id":1,"qr_token":"abc"}',
    ]) {
      expect(() => MachineQr.parse(raw), throwsFormatException);
    }
    final qr = MachineQr.parse('{"machine_id":"M001","qr_token":"abc"}');
    expect(qr.machineId, 'M001');
    expect(qr.token, 'abc');
  });

  test('temporary user ID persists and logout removes it', () async {
    final session = AppSession();
    await session.initialize();
    final userId = session.userId;
    expect(userId, isNotEmpty);
    session.userId = null;
    await session.initialize();
    expect(session.userId, userId);
    await session.logout();
    expect(
      (await SharedPreferences.getInstance()).getString('moyak_user_id'),
      isNull,
    );
  });

  test(
    'consultation captures chat context and ending does not approve medicine',
    () {
      final session = AppSession();
      session.chatSummary = '사용자: 질문';
      session.startConsultation(direct: false);
      final id = session.consultation!.id;
      session.chatSummary = '다른 대화';
      session.startConsultation(direct: false);
      expect(session.consultation!.id, id);
      expect(session.consultationChatSummary, '사용자: 질문');
      session.endPreviewConsultation();
      expect(session.consultation!.endedAt, isNotNull);
      expect(session.permits, isEmpty);
      session.startConsultation(direct: true);
      expect(session.consultation!.id, isNot(id));
    },
  );

  testWidgets('preview approval appears in permit list without delayed entry', (
    tester,
  ) async {
    AppConfig.preview.value = true;
    await phone(tester, const AppShell());
    await tester.pumpAndSettle();
    await tester.tap(find.text('상담하기'));
    await tester.pump();
    await tester.tap(find.text('상담 요청하기'));
    await tester.pump();
    await tester.tap(find.byType(DropdownButton<ConsultStatus>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('승인').last);
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('처방약: 예시 승인 약품'), findsOneWidget);
    expect(find.text('입장 전 화면과 소리를 확인해 주세요'), findsNothing);
    await tester.tap(find.text('마이'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('전자 구매 허가서'));
    await tester.pumpAndSettle();
    expect(find.text('예시 승인 약품'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('edited username ignores a stale availability response', (
    tester,
  ) async {
    final response = Completer<bool>();
    var continued = false;
    await phone(
      tester,
      SignupStep1Screen(
        onCheckAvailability: (_) => response.future,
        onNext: (_) => continued = true,
      ),
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    await tester.enterText(find.byType(TextField), 'first_user');
    await tester.tap(find.text('중복확인'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'second_user');
    response.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('✓ 사용 가능한 아이디입니다.'), findsNothing);
    await tester.tap(find.text('다음'));
    expect(continued, isFalse);
  });

  testWidgets('password form only advances with valid matching input', (
    tester,
  ) async {
    var continued = false;
    await phone(tester, SignupStep2Screen(onNext: () => continued = true));
    await tester.enterText(find.byType(TextField).at(0), 'Password1 ');
    await tester.enterText(find.byType(TextField).at(1), 'Password1 ');
    await tester.tap(find.text('다음'));
    expect(continued, isFalse);
    await tester.enterText(find.byType(TextField).at(0), 'Password1!');
    await tester.enterText(find.byType(TextField).at(1), 'Password1!');
    await tester.pump();
    await tester.tap(find.text('다음'));
    expect(continued, isTrue);
  });

  testWidgets('signup is one ordered scrollable form and retains input', (
    tester,
  ) async {
    await phone(tester, SignupFlow(onComplete: () {}));
    await tester.enterText(find.byKey(const Key('signup-name')), '홍길동');
    expect(
      tester.getTopLeft(find.byKey(const Key('signup-name'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const Key('signup-username'))).dy),
    );
    await tester.enterText(
      find.byKey(const Key('signup-username')),
      'moyak_user',
    );
    await tester.ensureVisible(find.text('가입 화면 미리보기 시작'));
    await tester.tap(find.text('가입 화면 미리보기 시작'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('중복확인'));
    await tester.tap(find.text('중복확인'));
    await tester.pumpAndSettle();
    expect(find.text('사용 가능한 아이디입니다.'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('signup-name')));
    expect(find.text('홍길동'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('login validates empty fields and explicitly enters preview', (
    tester,
  ) async {
    var entered = false;
    await phone(
      tester,
      LoginPage(onLogin: () => entered = true, onSignup: () {}),
    );
    await tester.tap(find.text('로그인').last);
    await tester.pump();
    expect(find.text('아이디와 비밀번호를 입력해주세요.'), findsOneWidget);
    expect(entered, isFalse);
    await tester.ensureVisible(find.text('회원가입 없이 화면 미리보기'));
    await tester.tap(find.text('회원가입 없이 화면 미리보기'));
    await tester.pumpAndSettle();
    expect(entered, isTrue);
    expect(AppConfig.preview.value, isTrue);
  });

  testWidgets('history supports empty, error and retry', (tester) async {
    var fail = true;
    await phone(
      tester,
      ConsultHistoryScreen(
        onOpenDetail: (_) {},
        loadRecords: () async {
          if (fail) throw StateError('offline');
          return <ConsultRecord>[];
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('상담 내역을 불러오지 못했어요.'), findsOneWidget);
    fail = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.textContaining('아직 약사 상담 내역이 없어요.'), findsOneWidget);
  });

  testWidgets('consultation survives tab changes without duplicate request', (
    tester,
  ) async {
    AppConfig.preview.value = true;
    await phone(tester, const AppShell());
    await tester.pumpAndSettle();
    await tester.tap(find.text('상담하기'));
    await tester.pump();
    await tester.tap(find.text('상담 요청하기'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    final id = AppSession.instance.consultation!.id;
    expect(find.textContaining('약사 입장을 기다리고 있어요'), findsOneWidget);
    await tester.tap(find.text('모약이'));
    await tester.pump();
    await tester.tap(find.text('상담하기'));
    await tester.pump();
    expect(AppSession.instance.consultation!.id, id);
    expect(find.textContaining('약사 입장을 기다리고 있어요'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('preview home and map detail fit a small phone', (tester) async {
    AppConfig.preview.value = true;
    await phone(
      tester,
      const AppShell(),
      size: const Size(320, 568),
      scale: 1.3,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('지도'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('미리보기 자판기'));
    await tester.tap(find.text('미리보기 자판기'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'permission explanation scrolls on a small screen with large text',
    (tester) async {
      await phone(
        tester,
        const PermissionScreen(),
        size: const Size(320, 568),
        scale: 1.5,
      );
      await tester.ensureVisible(find.text('계속하기'));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'call preview accepts text and confirms ending with keyboard open',
    (tester) async {
      await phone(
        tester,
        const VideoConsultationPage(
          video: ColoredBox(key: Key('test-remote-video'), color: Colors.blue),
        ),
        size: const Size(320, 568),
      );
      final videoElement = tester.element(
        find.byKey(const Key('test-remote-video')),
      );
      expect(find.byKey(const Key('consultation-chat-messages')), findsNothing);
      await tester.tap(find.byTooltip('채팅 열기'));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 220);
      await tester.enterText(find.byType(TextField), '미리보기 메시지');
      await tester.tap(find.byTooltip('메시지 보내기'));
      await tester.pumpAndSettle();
      expect(find.text('미리보기 메시지'), findsOneWidget);
      expect(
        tester.element(find.byKey(const Key('test-remote-video'))),
        same(videoElement),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('채팅 접기'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('consultation-chat-messages')), findsNothing);
      expect(find.byKey(const Key('consultation-chat-input')), findsOneWidget);
      expect(
        tester.element(find.byKey(const Key('test-remote-video'))),
        same(videoElement),
      );
      await tester.tap(find.byTooltip('채팅 열기'));
      await tester.pumpAndSettle();
      expect(find.text('미리보기 메시지'), findsOneWidget);
      await tester.tap(find.text('상담 종료'));
      await tester.pumpAndSettle();
      expect(find.text('상담 화면을 종료할까요?'), findsOneWidget);
      await tester.tap(find.text('계속 보기'));
      await tester.pumpAndSettle();
    },
  );
}
