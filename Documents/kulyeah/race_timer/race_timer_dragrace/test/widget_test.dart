import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:race_timer_dragrace/main.dart';

void main() {
  testWidgets('Race Timer smoke test', (WidgetTester tester) async {
    // Build app dan trigger frame
    await tester.pumpWidget(const RaceTimerApp());

    // Verifikasi teks judul di UI utama
    expect(find.text('RACE TIMER DRAG RACE'), findsOneWidget);
  });
}