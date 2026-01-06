import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('checkbox tag renders with label', (tester) async {
    await pumpTemplate(tester, '{% checkbox value: true label: "Alerts" %}');

    expect(find.text('Alerts'), findsOneWidget);
    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.value, isTrue);
  });
}
