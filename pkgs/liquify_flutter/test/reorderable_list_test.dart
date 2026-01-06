import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('reorderable_list wires reorder callback', (tester) async {
    var called = false;
    int? from;
    int? to;
    await pumpTemplate(
      tester,
      '''
{% reorderable_list items: items itemKey: "id" action: "reorder" shrinkWrap: true physics: "never" %}
  {% text value: item.label %}
{% endreorderable_list %}
''',
      data: {
        'items': [
          {'id': 'a', 'label': 'Alpha'},
          {'id': 'b', 'label': 'Beta'},
        ],
        'actions': {
          'reorder': (int oldIndex, int newIndex) {
            called = true;
            from = oldIndex;
            to = newIndex;
          },
        },
      },
    );

    final list = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    list.onReorder(0, 1);
    expect(called, isTrue);
    expect(from, 0);
    expect(to, 1);
  });

  testWidgets('reorderable_list_view alias renders', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% reorderable_list_view items: items itemKey: "id" shrinkWrap: true physics: "never" %}
  {% text value: item.label %}
{% endreorderable_list_view %}
''',
      data: {
        'items': [
          {'id': 'a', 'label': 'Alpha'},
          {'id': 'b', 'label': 'Beta'},
        ],
      },
    );

    expect(find.byType(ReorderableListView), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
  });
}
