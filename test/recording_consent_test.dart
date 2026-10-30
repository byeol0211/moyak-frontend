import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moyak/calls/recording_consent.dart';
import 'package:moyak/data/auth_session.dart';
import 'package:moyak/screens/video_consultation_page.dart';

class FakeRecordingConsent implements RecordingConsent {
  FakeRecordingConsent(this.state);

  RecordingConsentState? state;
  int consentCalls = 0;
  bool failStatus = false;
  Completer<RecordingConsentState?>? pendingStatus;
  int statusCalls = 0;

  @override
  Future<RecordingConsentState?> status() async {
    statusCalls++;
    if (pendingStatus != null) return pendingStatus!.future;
    if (failStatus) throw StateError('동의 상태를 확인하지 못했어요.');
    return state;
  }

  @override
  Future<RecordingConsentState> consent() async {
    consentCalls++;
    return state = RecordingConsentState(
      userConsented: true,
      pharmacistConsented: state?.pharmacistConsented ?? false,
      ended: false,
    );
  }

  @override
  void dispose() {}
}

Widget _page(RecordingConsent recording) =>
    MaterialApp(home: VideoConsultationPage(recording: recording));

void main() {
  for (final failOldRequest in [false, true]) {
    testWidgets(
      'late status ${failOldRequest ? 'error' : 'response'} cannot overwrite successful consent',
      (tester) async {
        const before = RecordingConsentState(
          userConsented: false,
          pharmacistConsented: true,
          ended: false,
        );
        final recording = FakeRecordingConsent(before);
        await tester.pumpWidget(_page(recording));
        await tester.pump();
        await tester.pump();
        recording.pendingStatus = Completer<RecordingConsentState?>();
        await tester.pump(const Duration(seconds: 3));
        expect(recording.statusCalls, 2);
        await tester.tap(find.byKey(const Key('recording-consent-agree')));
        await tester.pump();
        await tester.pump();
        expect(
          find.byKey(const Key('recording-consent-status')),
          findsOneWidget,
        );
        if (failOldRequest) {
          recording.pendingStatus!.completeError(
            StateError('old request failed'),
          );
        } else {
          recording.pendingStatus!.complete(before);
        }
        await tester.pump();
        await tester.pump();
        expect(
          find.byKey(const Key('recording-consent-status')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('recording-consent-card')), findsNothing);
        expect(
          find.byKey(const Key('recording-consent-status-error')),
          findsNothing,
        );
        expect(recording.consentCalls, 1);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets('status failure shows retry and recovers to consent card', (
    tester,
  ) async {
    final recording = FakeRecordingConsent(
      const RecordingConsentState(
        userConsented: false,
        pharmacistConsented: true,
        ended: false,
      ),
    )..failStatus = true;
    await tester.pumpWidget(_page(recording));
    await tester.pump();
    await tester.pump();
    expect(
      find.byKey(const Key('recording-consent-status-error')),
      findsOneWidget,
    );
    expect(find.textContaining('통화는 계속할 수 있어요'), findsOneWidget);
    expect(recording.consentCalls, 0);
    recording.failStatus = false;
    await tester.tap(find.byKey(const Key('recording-consent-retry')));
    await tester.pump();
    await tester.pump();
    expect(
      find.byKey(const Key('recording-consent-status-error')),
      findsNothing,
    );
    expect(find.byKey(const Key('recording-consent-card')), findsOneWidget);
  });
  testWidgets(
    'automatic status retry recovers without showing error for unassigned session',
    (tester) async {
      final recording = FakeRecordingConsent(null)..failStatus = true;
      await tester.pumpWidget(_page(recording));
      await tester.pump();
      await tester.pump();
      expect(
        find.byKey(const Key('recording-consent-status-error')),
        findsOneWidget,
      );
      recording.failStatus = false;
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      expect(
        find.byKey(const Key('recording-consent-status-error')),
        findsNothing,
      );
      expect(find.byKey(const Key('recording-consent-card')), findsNothing);
    },
  );
  testWidgets(
    'consent card appears after pharmacist connects and sends consent',
    (tester) async {
      final recording = FakeRecordingConsent(
        const RecordingConsentState(
          userConsented: false,
          pharmacistConsented: true,
          ended: false,
        ),
      );
      await tester.pumpWidget(_page(recording));
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('recording-consent-card')), findsOneWidget);
      expect(find.textContaining('내 휴대폰 마이크를 따로 녹음하지 않아요'), findsOneWidget);

      await tester.tap(find.byKey(const Key('recording-consent-agree')));
      await tester.pump();
      await tester.pump();

      expect(recording.consentCalls, 1);
      expect(find.byKey(const Key('recording-consent-card')), findsNothing);
      expect(find.text('AI 상담 요약 동의 완료 · 약사가 검토 후 공개해요'), findsOneWidget);
    },
  );

  testWidgets('no consent card before pharmacist connects', (tester) async {
    await tester.pumpWidget(_page(FakeRecordingConsent(null)));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('recording-consent-card')), findsNothing);
    expect(find.byKey(const Key('recording-consent-reopen')), findsNothing);
  });

  testWidgets('later hides card and keeps a way to consent', (tester) async {
    final recording = FakeRecordingConsent(
      const RecordingConsentState(
        userConsented: false,
        pharmacistConsented: false,
        ended: false,
      ),
    );
    await tester.pumpWidget(_page(recording));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byKey(const Key('recording-consent-later')));
    await tester.pump();
    expect(find.byKey(const Key('recording-consent-card')), findsNothing);
    expect(recording.consentCalls, 0);

    await tester.tap(find.byKey(const Key('recording-consent-reopen')));
    await tester.pump();
    expect(find.byKey(const Key('recording-consent-card')), findsOneWidget);
  });

  group('ApiRecordingConsent', () {
    setUp(AuthSession.clear);
    tearDown(AuthSession.clear);

    test(
      'expired login cannot fall back to guest or send any consent requests',
      () async {
        AuthSession.set('expired-token', -1);
        var calls = 0;
        final api = ApiRecordingConsent(
          consultationId: 'c1',
          userId: 'account-user',
          client: MockClient((_) async {
            calls++;
            return http.Response('{}', 200);
          }),
        );
        await expectLater(
          api.status(),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains('로그인이 만료'),
            ),
          ),
        );
        await expectLater(api.consent(), throwsStateError);
        expect(calls, 0);
      },
    );

    test('guest sends identity headers and 409 means not connected', () async {
      late http.Request seen;
      final api = ApiRecordingConsent(
        consultationId: 'c1',
        userId: 'guest-1',
        client: MockClient((request) async {
          seen = request;
          return http.Response('{"detail":"not connected"}', 409);
        }),
      );
      expect(await api.status(), isNull);
      expect(seen.url.path, '/consultations/c1/session');
      expect(seen.headers['X-Moyak-User-Id'], 'guest-1');
      expect(seen.headers['X-Moyak-Role'], 'user');
    });

    test('logged-in user sends bearer token when consenting', () async {
      AuthSession.set('token', 3600);
      late http.Request seen;
      final api = ApiRecordingConsent(
        consultationId: 'c1',
        userId: 'u1',
        client: MockClient((request) async {
          seen = request;
          return http.Response.bytes(
            utf8.encode(
              jsonEncode({
                'user_consent_at': '2026-10-27T12:00:00',
                'pharmacist_consent_at': null,
                'ended_at': null,
              }),
            ),
            200,
          );
        }),
      );
      final state = await api.consent();
      expect(seen.method, 'POST');
      expect(seen.url.path, '/consultations/c1/session/consent');
      expect(seen.headers['Authorization'], 'Bearer token');
      expect(seen.headers.containsKey('X-Moyak-Role'), isFalse);
      expect(state.userConsented, isTrue);
      expect(state.bothConsented, isFalse);
    });
  });
}
