import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('outlined_button renders label', (tester) async {
    await pumpTemplate(tester, '''
{% outlined_button label: "Outlined" %}
''');

    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.text('Outlined'), findsOneWidget);
  });
}
