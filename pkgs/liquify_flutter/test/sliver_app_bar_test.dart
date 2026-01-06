import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('sliver_app_bar renders title', (tester) async {
    await pumpTemplate(tester, '''
{% custom_scroll_view %}
  {% sliver_app_bar title: "Sliver" pinned: true %}
  {% sliver_list %}
    {% text value: "Row" %}
  {% endsliver_list %}
{% endcustom_scroll_view %}
''');

    expect(find.byType(SliverAppBar), findsOneWidget);
    expect(find.text('Sliver'), findsOneWidget);
  });
}
