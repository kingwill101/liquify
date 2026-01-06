// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('radio tag renders with group value', (tester) async {
    await pumpTemplate(
      tester,
      '{% radio value: "Daily" groupValue: "Daily" label: "Daily" %}',
    );

    final finder = find.byWidgetPredicate(
      (widget) => widget is RadioListTile<String>,
    );
    expect(finder, findsOneWidget);
    final radio = tester.widget<RadioListTile<String>>(finder);
    expect(radio.value, equals('Daily'));
    expect(radio.groupValue, equals('Daily'));
  });
}
