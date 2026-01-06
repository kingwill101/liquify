import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('paginated_data_table wires paging callbacks', (tester) async {
    int? rowsPerPage;
    int? pageStart;
    await pumpTemplate(
      tester,
      '''
{% paginated_data_table
  header: "Demo"
  columns: columns
  rows: rows
  rowsPerPage: 3
  availableRowsPerPage: rows_per_page
  onRowsPerPageChanged: "rows_per_page"
  onPageChanged: "page_changed" %}
''',
      data: {
        'columns': [
          {'label': 'Task'},
          {'label': 'Owner'},
        ],
        'rows': [
          {
            'cells': ['Alpha', 'Avery'],
          },
          {
            'cells': ['Beta', 'Morgan'],
          },
          {
            'cells': ['Gamma', 'Riley'],
          },
        ],
        'rows_per_page': [3, 5, 10],
        'actions': {
          'rows_per_page': (int value) {
            rowsPerPage = value;
          },
          'page_changed': (int value) {
            pageStart = value;
          },
        },
      },
    );

    final table = tester.widget<PaginatedDataTable>(
      find.byType(PaginatedDataTable),
    );
    expect(table.rowsPerPage, 3);
    table.onRowsPerPageChanged?.call(5);
    table.onPageChanged?.call(0);
    expect(rowsPerPage, 5);
    expect(pageStart, 0);
  });
}
