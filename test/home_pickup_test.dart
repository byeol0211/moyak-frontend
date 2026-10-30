import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moyak/data/models.dart';
import 'package:moyak/widgets/home_pickup_notice.dart';
import 'package:moyak/screens/main_home_disconnected_screen.dart';

PermitRecord permit(String name, PermitStatus status, {bool expired = false}) =>
    PermitRecord(
      drugName: name,
      status: status,
      issuedAt: DateTime.now(),
      expiresAt: DateTime.now().add(Duration(days: expired ? -1 : 1)),
      pharmacist: '약사',
    );

void main() {
  testWidgets(
    'pickup shows only unexpired available permits and QR opens scanner',
    (tester) async {
      var scans = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomePickupNotice(
              loadPermits: () async => [
                permit('수령할 약', PermitStatus.available),
                permit('기한 지난 약', PermitStatus.available, expired: true),
                permit('수령 완료 약', PermitStatus.dispensed),
                permit('취소 약', PermitStatus.cancelled),
                permit('알 수 없는 상태 약', PermitStatus.unknown),
              ],
              onScanQr: () => scans++,
              onOpenPermits: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('수령할 약'), findsOneWidget);
      for (final name in ['기한 지난 약', '수령 완료 약', '취소 약', '알 수 없는 상태 약']) {
        expect(find.text(name), findsNothing);
      }
      expect(find.textContaining('수령 기한'), findsOneWidget);
      await tester.tap(find.text('자판기 QR 스캔'));
      expect(scans, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'pickup request failure can retry and empty response hides notice',
    (tester) async {
      var fail = true;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomePickupNotice(
              loadPermits: () async {
                if (fail) throw Exception('offline');
                return [];
              },
              onScanQr: () {},
              onOpenPermits: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('수령 가능한 약을 확인하지 못했어요.'), findsOneWidget);
      expect(find.text('자판기 QR 스캔'), findsNothing);
      fail = false;
      await tester.tap(find.text('재시도'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home-pickup-notice')), findsNothing);
      expect(find.text('수령 가능한 약을 확인하지 못했어요.'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'machine information and explicit actions fit small screen with pickup',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var stores = 0;
      var changes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MainHomeConnectedScreen(
              machineName: '학생회관 자판기',
              operatingHours: '09:00 ~ 18:00',
              distanceLabel: '내 위치에서 약 250m',
              onScanQr: () {},
              onOpenStore: () => stores++,
              onChangeMachine: () => changes++,
              pickupNotice: HomePickupNotice(
                loadPermits: () async => [
                  permit('승인된 약', PermitStatus.available),
                ],
                onScanQr: () {},
                onOpenPermits: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('재고 보기'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('내 위치에서 약 250m'), findsOneWidget);
      expect(find.text('운영시간 · 09:00 ~ 18:00'), findsOneWidget);
      await tester.tap(find.text('재고 보기'));
      await tester.tap(find.text('자판기 변경'));
      expect(stores, 1);
      expect(changes, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
