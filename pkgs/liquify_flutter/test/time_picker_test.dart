import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('time_picker tag emits selected time', (tester) async {
    String? selected;
    await pumpTemplate(
      tester,
      '{% time_picker value: "09:30" entryMode: "input" action: "pick" confirmText: "Select" helpText: "Pick a time" %}',
      data: {
        'actions': {'pick': (String value) => selected = value},
      },
    );

    await tester.tap(find.byWidgetPredicate((widget) => widget is TextButton));
    await tester.pumpAndSettle();
    expect(find.text('Pick a time'), findsOneWidget);
    await tester.tap(find.text('Select'));
    await tester.pumpAndSettle();

    expect(selected, '09:30');
  });
}
