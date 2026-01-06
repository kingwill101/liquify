import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('table renders rows from data', (tester) async {
    await pumpTemplate(
      tester,
      '''
{% table rows: rows %}
{% endtable %}
''',
      data: {
        'rows': [
          ['Name', 'Value'],
          ['Alpha', '1'],
          ['Beta', '2'],
        ],
      },
    );

    final table = tester.widget<Table>(find.byType(Table));
    expect(table.children.length, 3);
  });
}
