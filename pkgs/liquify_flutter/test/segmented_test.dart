import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('segmented tag renders with labels', (tester) async {
    await pumpTemplate(
      tester,
      '{% segmented labels: labels selectedIndex: 1 %}',
      data: {
        'labels': ['One', 'Two', 'Three'],
      },
    );

    expect(
      find.byWidgetPredicate((widget) => widget is SegmentedButton<int>),
      findsOneWidget,
    );
    expect(find.text('Two'), findsOneWidget);
  });

  testWidgets('segmented tag supports multi selection', (tester) async {
    await pumpTemplate(
      tester,
      '{% segmented labels: labels selected: selected multiSelectionEnabled: true direction: "vertical" %}',
      data: {
        'labels': ['One', 'Two', 'Three'],
        'selected': [0, 2],
      },
    );

    final segmented = tester.widget<SegmentedButton<int>>(
      find.byType(SegmentedButton<int>),
    );
    expect(segmented.multiSelectionEnabled, isTrue);
    expect(segmented.direction, Axis.vertical);
    expect(segmented.selected, {0, 2});
  });
}
