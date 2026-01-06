import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('date_picker tag emits selected date', (tester) async {
    String? selected;
    await pumpTemplate(
      tester,
      '{% date_picker value: "2025-12-24" action: "pick" confirmText: "Select" helpText: "Pick a date" %}',
      data: {
        'actions': {'pick': (String value) => selected = value},
      },
    );

    await tester.tap(find.byWidgetPredicate((widget) => widget is TextButton));
    await tester.pumpAndSettle();
    expect(find.text('Pick a date'), findsOneWidget);
    await tester.tap(find.text('Select'));
    await tester.pumpAndSettle();

    expect(selected, '2025-12-24');
  });
}
