import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('toggle_buttons tag renders with labels', (tester) async {
    await pumpTemplate(
      tester,
      '{% toggle_buttons labels: labels selectedIndex: 0 %}',
      data: {
        'labels': ['Left', 'Right'],
      },
    );

    expect(find.byType(ToggleButtons), findsOneWidget);
    expect(find.text('Left'), findsOneWidget);
  });

  testWidgets('toggle_buttons tag renders icon items', (tester) async {
    await pumpTemplate(
      tester,
      '{% toggle_buttons icons: icons selectedIndex: 1 %}',
      data: {
        'icons': ['home', 'star', 'settings'],
      },
    );

    expect(find.byType(ToggleButtons), findsOneWidget);
    expect(find.byType(Icon), findsWidgets);
  });

  testWidgets('toggle_buttons tag applies layout properties', (tester) async {
    await pumpTemplate(
      tester,
      '{% toggle_buttons labels: labels selectedIndex: 0 direction: "vertical" renderBorder: false tapTargetSize: "shrinkWrap" disabledColor: "#ff0000" %}',
      data: {
        'labels': ['One', 'Two'],
      },
    );

    final toggle = tester.widget<ToggleButtons>(find.byType(ToggleButtons));
    expect(toggle.direction, Axis.vertical);
    expect(toggle.renderBorder, isFalse);
    expect(toggle.tapTargetSize, MaterialTapTargetSize.shrinkWrap);
    expect(toggle.disabledColor, const Color(0xFFFF0000));
  });
}
