import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('indexed_stack renders with selected index', (tester) async {
    await pumpTemplate(tester, '''
{% indexed_stack index: 1 %}
  {% text value: "First" %}
  {% text value: "Second" %}
  {% text value: "Third" %}
{% endindexed_stack %}
''');

    final widget = tester.widget<IndexedStack>(find.byType(IndexedStack));
    expect(widget.index, 1);
    expect(widget.children.length, 3);
    expect(find.text('Second'), findsOneWidget);
  });

  testWidgets('indexed_stack enforces strict args', (tester) async {
    expect(
      () => pumpTemplate(
        tester,
        '{% indexed_stack unknown: 1 %}{% endindexed_stack %}',
        strictTags: true,
      ),
      throwsException,
    );
  });
}
