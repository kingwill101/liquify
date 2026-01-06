import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('bottom_app_bar renders child content', (tester) async {
    await pumpTemplate(
      tester,
      '{% bottom_app_bar color: "#111827" %}'
      '{% row %}{% icon name: "menu" %}{% text value: "Menu" %}{% endrow %}'
      '{% endbottom_app_bar %}',
    );

    expect(find.byType(BottomAppBar), findsOneWidget);
    expect(find.text('Menu'), findsOneWidget);
  });

  testWidgets('bottom_app_bar enforces strict args', (tester) async {
    expect(
      () => pumpTemplate(
        tester,
        '{% bottom_app_bar unknown: 1 %}{% endbottom_app_bar %}',
        strictTags: true,
      ),
      throwsException,
    );
  });
}
