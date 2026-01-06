import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('simple_dialog renders title', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% simple_dialog title: "Options" %}
  {% text value: "One" %}
{% endsimple_dialog %}
''',
    );

    expect(find.byType(SimpleDialog), findsOneWidget);
    expect(find.text('Options'), findsOneWidget);
  });
}
