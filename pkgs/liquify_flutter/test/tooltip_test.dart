import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('tooltip renders with message', (tester) async {
    await pumpTemplate(
      tester,
      '{% tooltip message: "Info" %}'
      '{% text value: "Hover" %}'
      '{% endtooltip %}',
    );

    final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(tooltip.message, 'Info');
    expect(find.text('Hover'), findsOneWidget);
  });

  testWidgets('tooltip enforces strict args', (tester) async {
    expect(
      () => pumpTemplate(
        tester,
        '{% tooltip message: "Info" unknown: 1 %}{% endtooltip %}',
        strictTags: true,
      ),
      throwsException,
    );
  });
}
