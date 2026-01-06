import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('tab_bar_view renders children with controller', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% tab_bar_view length: 2 %}
  {% text value: "Tab A" %}
  {% text value: "Tab B" %}
{% endtab_bar_view %}
''',
    );

    expect(find.byType(TabBarView), findsOneWidget);
    expect(find.byType(DefaultTabController), findsOneWidget);
    final view = tester.widget<TabBarView>(find.byType(TabBarView));
    expect(view.children.length, 2);
    expect(find.text('Tab A'), findsOneWidget);
  });

  testWidgets('tab_bar_view enforces strict args', (tester) async {
    expect(
      () => pumpTemplate(
        tester,
        '{% tab_bar_view unknown: 1 %}{% endtab_bar_view %}',
        strictTags: true,
      ),
      throwsException,
    );
  });
}
