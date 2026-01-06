import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('sliver_persistent_header renders child', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% custom_scroll_view %}
  {% sliver_persistent_header minExtent: 48 maxExtent: 96 pinned: true %}
    {% text value: "Header" %}
  {% endsliver_persistent_header %}
  {% sliver_list %}
    {% text value: "Row" %}
  {% endsliver_list %}
{% endcustom_scroll_view %}
''',
    );

    expect(find.byType(SliverPersistentHeader), findsOneWidget);
    expect(find.text('Header'), findsOneWidget);
  });
}
