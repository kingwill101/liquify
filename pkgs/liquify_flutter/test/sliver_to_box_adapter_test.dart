import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('sliver_to_box_adapter renders child', (tester) async {
    await pumpTemplate(tester, '''
{% custom_scroll_view %}
  {% sliver_to_box_adapter %}
    {% text value: "Adapter" %}
  {% endsliver_to_box_adapter %}
{% endcustom_scroll_view %}
''');

    expect(find.byType(SliverToBoxAdapter), findsOneWidget);
    expect(find.text('Adapter'), findsOneWidget);
  });
}
