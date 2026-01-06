import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('limited_box maps max sizes', (tester) async {
    await pumpTemplate(
      tester,
      '{% limited_box maxWidth: 120 maxHeight: 80 %}'
      '{% text value: "Limit" %}'
      '{% endlimited_box %}',
    );

    final finder = find.byType(LimitedBox);
    expect(finder, findsOneWidget);
    final box = tester.widget<LimitedBox>(finder);
    expect(box.maxWidth, 120);
    expect(box.maxHeight, 80);
  });
}
