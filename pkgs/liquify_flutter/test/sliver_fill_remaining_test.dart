import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('sliver_fill_remaining renders child', (tester) async {
    await pumpTemplate(tester, '''
{% custom_scroll_view %}
  {% sliver_fill_remaining hasScrollBody: false %}
    {% text value: "Fill" %}
  {% endsliver_fill_remaining %}
{% endcustom_scroll_view %}
''');

    expect(find.byType(SliverFillRemaining), findsOneWidget);
    expect(find.text('Fill'), findsOneWidget);
  });
}
