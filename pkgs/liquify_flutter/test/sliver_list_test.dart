import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('sliver_list renders items', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% custom_scroll_view %}
  {% sliver_list items: items %}
    {% text value: item.label %}
  {% endsliver_list %}
{% endcustom_scroll_view %}
''',
      data: {
        'items': [
          {'label': 'Alpha'},
          {'label': 'Beta'},
        ],
      },
    );

    expect(find.byType(SliverList), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
  });
}
