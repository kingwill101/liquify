import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('elevated_button renders label', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% elevated_button label: "Elevated" %}
''',
    );

    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.text('Elevated'), findsOneWidget);
  });
}
