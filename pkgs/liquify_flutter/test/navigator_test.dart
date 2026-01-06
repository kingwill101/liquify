import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_utils.dart';

void main() {
  testWidgets('navigator renders top page', (tester) async {
    await pumpTemplate(
      tester,
      '{% navigator %}'
      '{% text value: "First" %}'
      '{% text value: "Second" %}'
      '{% endnavigator %}',
    );

    expect(find.byType(Navigator), findsWidgets);
    expect(find.text('Second'), findsOneWidget);
  });
}
