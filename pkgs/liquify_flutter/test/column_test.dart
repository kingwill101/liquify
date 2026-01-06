import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('column tag renders children with spacing', (tester) async {
    await pumpTemplate(
      tester,
      '{% column spacing: 6 %}{% text value: "A" %}{% text value: "B" %}'
      '{% endcolumn %}',
    );

    final column = tester.widget<Column>(find.byType(Column));
    expect(column.spacing, 6);
  });
}
