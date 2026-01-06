import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('badge tag renders label', (tester) async {
    await pumpTemplate(tester, '{% badge label: "New" %}{% endbadge %}');

    expect(find.byType(Badge), findsOneWidget);
    expect(find.text('New'), findsOneWidget);
  });

  testWidgets('badge count renders numeric label', (tester) async {
    await pumpTemplate(tester, '{% badge count: 3 %}{% endbadge %}');

    expect(find.byType(Badge), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('badge tag applies label style', (tester) async {
    await pumpTemplate(
      tester,
      '{% badge label: "New" labelStyle: style %}{% endbadge %}',
      data: {
        'style': {
          'color': '#00ff00',
          'fontSize': 12,
        },
      },
    );

    final badge = tester.widget<Badge>(find.byType(Badge));
    expect(badge.textStyle?.color, const Color(0xFF00FF00));
    expect(badge.textStyle?.fontSize, 12);
  });
}
