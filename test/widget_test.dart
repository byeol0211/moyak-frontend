// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:moyak/main.dart';

void main() {
  testWidgets('shows the login screen after splash', (WidgetTester tester) async {
    await tester.pumpWidget(const MoyakApp());
    expect(find.bySemanticsLabel('모약이에 온 걸 환영해! 약 자판기 마스코트'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle();

    await tester.tap(find.text('허용하기'));
    await tester.pumpAndSettle();

    expect(find.text('로그인'), findsNWidgets(2));
    expect(find.text('아이디'), findsOneWidget);
  });
}
