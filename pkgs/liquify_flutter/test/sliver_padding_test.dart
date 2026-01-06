import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('sliver_padding wraps sliver content', (tester) async {
    await pumpTemplate(tester, '''
{% custom_scroll_view %}
  {% sliver_padding padding: 12 %}
    {% sliver_list %}
      {% text value: "Padded" %}
    {% endsliver_list %}
  {% endsliver_padding %}
{% endcustom_scroll_view %}
''');

    expect(find.byType(SliverPadding), findsOneWidget);
    expect(find.text('Padded'), findsOneWidget);
  });
}
