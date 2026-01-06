import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('filled_button renders label', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% filled_button label: "Filled" %}
''',
    );

    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.text('Filled'), findsOneWidget);
  });
}
