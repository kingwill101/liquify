import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('fractionally_sized_box maps factors', (tester) async {
    await pumpTemplate(
      tester,
      '{% fractionally_sized_box widthFactor: 0.5 heightFactor: 0.25 %}'
      '{% text value: "Box" %}'
      '{% endfractionally_sized_box %}',
    );

    final finder = find.byType(FractionallySizedBox);
    expect(finder, findsOneWidget);
    final box = tester.widget<FractionallySizedBox>(finder);
    expect(box.widthFactor, 0.5);
    expect(box.heightFactor, 0.25);
  });
}
