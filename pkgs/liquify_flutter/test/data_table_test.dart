import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('data_table builds columns and rows', (tester) async {
    var sorted = false;
    await pumpTemplate(
      tester,
      '''
{% data_table columns: columns rows: rows action: "sort" %}
''',
      data: {
        'columns': [
          {'label': 'Name'},
          {'label': 'Score', 'numeric': true},
        ],
        'rows': [
          {'cells': ['Alpha', '1']},
          {'cells': ['Beta', '2']},
        ],
        'actions': {
          'sort': (int columnIndex, bool ascending) {
            sorted = true;
          },
        },
      },
    );

    final table = tester.widget<DataTable>(find.byType(DataTable));
    expect(table.columns.length, 2);
    expect(table.rows.length, 2);
    table.columns.first.onSort?.call(0, true);
    expect(sorted, isTrue);
  });
}
