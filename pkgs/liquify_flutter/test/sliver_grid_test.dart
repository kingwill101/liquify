import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('sliver_grid renders grid items', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% custom_scroll_view %}
  {% sliver_grid columns: 2 %}
    {% container %}{% text value: "A" %}{% endcontainer %}
    {% container %}{% text value: "B" %}{% endcontainer %}
  {% endsliver_grid %}
{% endcustom_scroll_view %}
''',
    );

    expect(find.byType(SliverGrid), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
  });
}
