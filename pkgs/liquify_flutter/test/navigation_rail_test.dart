import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('navigation_rail builds destinations', (tester) async {
    await pumpTemplate(
      tester,
      '{% navigation_rail selectedIndex: 1 labelType: "all" %}'
      '{% navigation_destination label: "Home" icon: "home" %}'
      '{% navigation_destination label: "Search" icon: "search" %}'
      '{% endnavigation_rail %}',
    );

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.destinations.length, 2);
    expect(rail.selectedIndex, 1);
  });

  testWidgets('navigation_destination enforces strict args', (tester) async {
    expect(
      () => pumpTemplate(
        tester,
        '{% navigation_rail %}'
        '{% navigation_destination label: "Home" icon: "home" unknown: 1 %}'
        '{% endnavigation_rail %}',
        strictTags: true,
      ),
      throwsException,
    );
  });
}
