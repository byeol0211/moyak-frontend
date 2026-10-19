import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moyak/screens/main_home_disconnected_screen.dart';

Future<void> _pumpHome(WidgetTester tester, {bool visible = true}) async {
  tester.view.physicalSize = const Size(402, 874);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TickerMode(
          enabled: visible,
          child: MainHomeDisconnectedScreen(
            onScanQr: () {},
            onRescanDevice: () {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('ad banner advances automatically through 4 pages', (
    tester,
  ) async {
    await _pumpHome(tester);
    expect(find.text('1/4'), findsOneWidget);
    expect(find.text('급한 의약품이 있다면? 자판기에서 바로!'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('2/4'), findsOneWidget);
    expect(find.text('무슨 약이 필요한지 모르겠다면? 모약이에게!'), findsOneWidget);

    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    }
    // 4/4 다음에는 다시 1/4로 이어진다.
    expect(find.text('1/4'), findsOneWidget);
  });

  testWidgets('ad banner can be swiped forward and back', (tester) async {
    await _pumpHome(tester);

    await tester.fling(find.text('1/4'), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('2/4'), findsOneWidget);

    await tester.fling(find.text('2/4'), const Offset(300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('1/4'), findsOneWidget);

    // 처음 광고에서 뒤로 넘기면 마지막 광고가 나온다.
    await tester.fling(find.text('1/4'), const Offset(300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('4/4'), findsOneWidget);
  });

  testWidgets('ad banner stays put while the home tab is hidden', (
    tester,
  ) async {
    await _pumpHome(tester, visible: false);

    await tester.pump(const Duration(seconds: 12));
    await tester.pumpAndSettle();
    expect(find.text('1/4'), findsOneWidget);
  });
}
