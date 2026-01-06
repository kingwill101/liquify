import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('selectable_text renders text', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% selectable_text value: "Selectable" %}
''',
    );

    expect(find.byType(SelectableText), findsOneWidget);
    expect(find.text('Selectable'), findsOneWidget);
  });
}
