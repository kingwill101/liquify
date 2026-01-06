import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('expansion_tile renders title and children', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% expansion_tile title: "Filters" initiallyExpanded: true %}
  {% text value: "Item A" %}
  {% text value: "Item B" %}
{% endexpansion_tile %}
''',
    );

    expect(find.byType(ExpansionTile), findsOneWidget);
    expect(find.text('Filters'), findsOneWidget);
    expect(find.text('Item A'), findsOneWidget);
    expect(find.text('Item B'), findsOneWidget);
  });

  testWidgets('expansion_tile enforces strict args', (tester) async {
    expect(
      () => pumpTemplate(
        tester,
        '{% expansion_tile unknown: 1 %}{% endexpansion_tile %}',
        strictTags: true,
      ),
      throwsException,
    );
  });
}
