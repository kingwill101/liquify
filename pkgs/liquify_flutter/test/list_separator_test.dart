import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('list_separator adds separators to list_view_builder', (
    tester,
  ) async {
    await pumpTemplate(
      tester,
      '''
{% container %}
  {% list_separator %}
    {% divider color: "#1f2937" %}
  {% endlist_separator %}
  {% list_view_builder items: items shrinkWrap: true physics: "never" %}
    {% text value: item %}
  {% endlist_view_builder %}
{% endcontainer %}
''',
      data: {
        'items': ['Alpha', 'Beta', 'Gamma'],
      },
    );

    expect(find.byType(Divider), findsNWidgets(2));
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    expect(find.text('Gamma'), findsOneWidget);
  });

  testWidgets('list_separator enforces strict args', (tester) async {
    expect(
      () => pumpTemplate(
        tester,
        '{% list_separator unknown: 1 %}{% endlist_separator %}',
        strictTags: true,
      ),
      throwsException,
    );
  });
}
