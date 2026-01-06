import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('card tag applies padding', (tester) async {
    await pumpTemplate(
      tester,
      '{% card padding: 8 %}{% text value: "Card" %}{% endcard %}',
    );

    expect(find.byType(Card), findsOneWidget);
    final paddingFinder =
        find.ancestor(of: find.text('Card'), matching: find.byType(Padding));
    final padding = tester.widget<Padding>(paddingFinder.first);
    expect(padding.padding, const EdgeInsets.all(8));
    expect(find.text('Card'), findsOneWidget);
  });
}
