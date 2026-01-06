import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('bottom_nav builds items and respects currentIndex', (tester) async {
    await pumpTemplate(
      tester,
      '{% bottom_nav currentIndex: 1 %}'
      '{% bottom_nav_item label: "Home" icon: "home" %}'
      '{% bottom_nav_item label: "Search" icon: "search" %}'
      '{% endbottom_nav %}',
    );

    final bar = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(bar.items.length, 2);
    expect(bar.currentIndex, 1);
  });

  testWidgets('bottom_nav_item enforces strict args', (tester) async {
    expect(
      () => pumpTemplate(
        tester,
        '{% bottom_nav %}'
        '{% bottom_nav_item label: "Home" icon: "home" unknown: 1 %}'
        '{% endbottom_nav %}',
        strictTags: true,
      ),
      throwsException,
    );
  });
}
