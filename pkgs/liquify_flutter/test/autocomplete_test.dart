import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('autocomplete renders with options', (tester) async {
    await pumpTemplate(tester, '''
{% autocomplete options: "Alpha,Beta,Gamma" initialValue: "Alpha" %}
''');

    expect(find.byType(Autocomplete), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
  });
}
