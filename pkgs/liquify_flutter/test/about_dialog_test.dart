import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('about_dialog renders app info', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% about_dialog applicationName: "Liquify" applicationVersion: "0.1" %}
  {% text value: "Info" %}
{% endabout_dialog %}
''',
    );

    expect(find.byType(AboutDialog), findsOneWidget);
    expect(find.text('Liquify'), findsOneWidget);
  });
}
