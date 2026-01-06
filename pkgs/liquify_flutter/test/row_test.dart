import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('row tag renders children with spacing', (tester) async {
    await pumpTemplate(
      tester,
      '{% row spacing: 8 %}{% text value: "A" %}{% text_button text: "B" %}{% endrow %}',
    );

    final row = tester.widget<Row>(find.byType(Row));
    expect(row.spacing, 8);
  });
}
