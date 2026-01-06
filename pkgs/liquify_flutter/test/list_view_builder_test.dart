import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('list_view_builder renders items from list', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% list_view_builder items: items gap: 8 shrinkWrap: true physics: "never" %}
  {% text value: item.label %}
{% endlist_view_builder %}
''',
      data: {
        'items': [
          {'label': 'Alpha'},
          {'label': 'Beta'},
        ],
      },
    );

    expect(find.byType(ListView), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    final listView = tester.widget<ListView>(find.byType(ListView));
    final delegate = listView.childrenDelegate as SliverChildBuilderDelegate;
    expect(delegate.childCount, 2);
  });
}
